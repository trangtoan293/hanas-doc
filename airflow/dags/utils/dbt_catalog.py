from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional


logger = logging.getLogger(__name__)


class DbtCatalogBuilder:
    @staticmethod
    def build_from_manifest_sql(
        manifest_path: str,
        run_results_path: str,
        output_path: str,
    ) -> int:
        try:
            manifest = DbtCatalogBuilder._read_json(Path(manifest_path)) or {}
            run_results = DbtCatalogBuilder._read_json(Path(run_results_path)) or {}
        except Exception as exc:
            logger.warning("Could not read artifacts: %s", exc)
            return 0

        nodes = manifest.get("nodes", {}) or {}
        rr_map: Dict[str, str] = {}
        for res in (run_results.get("results") or []):
            uid = res.get("unique_id")
            if not uid:
                continue
            sql = res.get("compiled_code") or res.get("compiled_sql")
            if sql:
                rr_map[uid] = sql

        def _split_select_list(s: str) -> List[str]:
            out: List[str] = []
            buf: List[str] = []
            depth = 0
            in_sq = False
            in_dq = False
            i = 0
            while i < len(s):
                ch = s[i]
                if not in_sq and not in_dq:
                    if ch == "(":
                        depth += 1
                    elif ch == ")":
                        depth = max(0, depth - 1)
                    elif ch == "'":
                        in_sq = True
                    elif ch == '"':
                        in_dq = True
                    elif ch == "," and depth == 0:
                        part = "".join(buf).strip()
                        if part:
                            out.append(part)
                        buf = []
                        i += 1
                        continue
                else:
                    if in_sq and ch == "'":
                        in_sq = False
                    elif in_dq and ch == '"':
                        in_dq = False
                buf.append(ch)
                i += 1
            tail = "".join(buf).strip()
            if tail:
                out.append(tail)
            return out

        def _strip_sql_comments(sql: str) -> str:
            import re

            sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.S)
            sql = re.sub(r"--[^\n]*", " ", sql)
            return sql

        def _find_top_level(sql: str, keyword: str, start: int = 0) -> int:
            low = sql.lower()
            kw = keyword.lower()
            depth = 0
            in_sq = False
            in_dq = False
            i = start
            n = len(sql)
            m = len(kw)
            while i <= n - m:
                ch = sql[i]
                if not in_sq and not in_dq:
                    if ch == "(":
                        depth += 1
                        i += 1
                        continue
                    if ch == ")":
                        depth = max(0, depth - 1)
                        i += 1
                        continue
                    if ch == "'":
                        in_sq = True
                        i += 1
                        continue
                    if ch == '"':
                        in_dq = True
                        i += 1
                        continue
                    if depth == 0 and low.startswith(kw, i):
                        before_ok = i == 0 or not low[i - 1].isalnum()
                        after_ok = i + m == n or not low[i + m].isalnum()
                        if before_ok and after_ok:
                            return i
                else:
                    if in_sq and ch == "'":
                        in_sq = False
                    elif in_dq and ch == '"':
                        in_dq = False
                i += 1
            return -1

        def _extract_cols(sql: str) -> List[str]:
            if not sql:
                return []
            sql_nc = _strip_sql_comments(sql)
            sel = _find_top_level(sql_nc, "select", 0)
            if sel < 0:
                return []
            frm = _find_top_level(sql_nc, "from", sel + 6)
            if frm < 0:
                return []
            inner = sql_nc[sel + 6 : frm]
            parts = _split_select_list(inner)
            cols: List[str] = []
            invalid_tokens = {
                "desc",
                "asc",
                "from",
                "where",
                "when",
                "then",
                "else",
                "end",
                "join",
                "on",
                "group",
                "order",
                "limit",
                "union",
                "intersect",
                "except",
            }
            import re

            ident_re = re.compile(r"^[`\"]?([A-Za-z_][\w$]*)[`\"]?$")
            for p in parts:
                token = p.strip()
                if not token or token == "*" or token.endswith(".*"):
                    continue
                low = token.lower()
                alias = None
                idx = low.rfind(" as ")
                if idx != -1:
                    alias = token[idx + 4 :].strip()
                else:
                    toks = token.split()
                    if toks:
                        cand = toks[-1]
                        if cand.lower() not in invalid_tokens:
                            alias = cand
                if not alias:
                    if "." in token:
                        alias = token.split(".")[-1]
                    else:
                        alias = token
                alias = alias.strip().strip('`"')
                if (
                    not alias
                    or alias.lower() in invalid_tokens
                    or not ident_re.match(alias)
                ):
                    continue
                cols.append(alias)
            return cols

        def _extract_cols_sqlglot(sql: str) -> List[str]:
            try:
                import sqlglot
                from sqlglot import exp
            except Exception:
                return []
            try:
                tree = sqlglot.parse_one(sql, read="spark")
            except Exception:
                return []

            def _get_select(node: "exp.Expression") -> Optional["exp.Select"]:
                if isinstance(node, exp.Union):
                    return _get_select(node.left)
                if isinstance(node, exp.Subquery):
                    return _get_select(node.this)
                if isinstance(node, exp.Select):
                    return node
                return None

            select = _get_select(tree)
            if not select:
                return []

            exprs = list(select.expressions or [])
            out_cols: List[str] = []
            for e in exprs:
                try:
                    if e.alias:
                        name = e.alias
                    elif isinstance(e, exp.Column):
                        name = e.name or e.this.name if hasattr(e, "this") else str(e)
                    else:
                        sql_repr = e.sql(dialect="spark").strip()
                        tokens = sql_repr.split()
                        if tokens:
                            last_token = tokens[-1].strip('`"')
                            if last_token.upper() not in {
                                "FROM",
                                "WHERE",
                                "WHEN",
                                "THEN",
                                "ELSE",
                                "END",
                                "AS",
                            }:
                                name = last_token
                            else:
                                name = (
                                    tokens[0].strip('`"')
                                    if len(tokens) > 0
                                    else sql_repr
                                )
                        else:
                            name = sql_repr
                    name = str(name).strip('`"').strip()
                    if name and name not in out_cols and not name.upper().startswith(
                        "SELECT"
                    ):
                        out_cols.append(name)
                except Exception:
                    continue
            return out_cols

        def _extract_cols_combined(sql: str, db: str, schema: str) -> List[str]:
            cols = _extract_cols_sqlglot(sql)
            if cols:
                return cols
            cols = _extract_cols(sql)
            if cols:
                return cols
            try:
                from datahub.sql_parsing.sqlglot_lineage import (
                    create_lineage_sql_parsed_result,
                )
            except Exception:
                return []
            try:
                res = create_lineage_sql_parsed_result(
                    query=sql,
                    graph=None,
                    platform="iceberg",
                    platform_instance=None,
                    env="PROD",
                    default_db=db or None,
                    default_schema=str(schema) or None,
                    override_dialect="spark",
                )
            except Exception:
                return []
            cols = []
            try:
                cll = getattr(res, "column_lineage", None)
                if not cll:
                    return []
                for cl in cll:
                    try:
                        d = getattr(cl, "downstream", None)
                        c = getattr(d, "column", None) if d is not None else None
                        if not c and isinstance(cl, dict):
                            d = cl.get("downstream")
                            c = (d or {}).get("column")
                        if c and c not in cols:
                            cols.append(str(c))
                    except Exception:
                        continue
            except Exception:
                return []
            return cols

        out: Dict[str, Any] = {"nodes": {}, "sources": {}, "metadata": {}}
        added = 0
        for uid, node in nodes.items():
            rt = (node.get("resource_type") or "").lower()
            if rt not in {"model", "snapshot"}:
                continue
            db = (node.get("database") or "").strip()
            schema = (node.get("schema") or "").strip()
            name = (node.get("alias") or node.get("name") or "").strip()
            if not name or not schema:
                continue
            sql = rr_map.get(uid) or node.get("compiled_code") or node.get("compiled_sql") or ""
            parser_cols = _extract_cols_combined(sql, db, schema)
            logger.info(
                "📊 %s: SQL parser extracted %d cols",
                name,
                len(parser_cols or []),
            )
            if parser_cols:
                logger.info(
                    "   Extracted columns: %s%s",
                    (parser_cols or [])[:10],
                    "..." if len(parser_cols or []) > 10 else "",
                )

            def _clean(col: str) -> str:
                try:
                    s = str(col)
                    s = s.strip().strip('`"')
                    if s == "*" or not s:
                        return ""
                    return s
                except Exception:
                    return ""

            if not parser_cols:
                continue

            projection_labels: List[str] = []
            try:
                raw_sql = _strip_sql_comments(sql or "")
                sel_pos = _find_top_level(raw_sql, "select", 0)
                frm_pos = _find_top_level(raw_sql, "from", sel_pos + 6) if sel_pos >= 0 else -1
                if sel_pos >= 0 and frm_pos > sel_pos:
                    proj = raw_sql[sel_pos + 6 : frm_pos]
                    parts: List[str] = []
                    buf: List[str] = []
                    depth = 0
                    in_sq = False
                    in_dq = False
                    for ch in proj:
                        if ch == "'" and not in_dq:
                            in_sq = not in_sq
                        elif ch == '"' and not in_sq:
                            in_dq = not in_dq
                        elif ch == "(" and not in_sq and not in_dq:
                            depth += 1
                        elif ch == ")" and not in_sq and not in_dq:
                            depth = max(0, depth - 1)
                        if ch == "," and depth == 0 and not in_sq and not in_dq:
                            parts.append("".join(buf).strip())
                            buf = []
                        else:
                            buf.append(ch)
                    tail = "".join(buf).strip()
                    if tail:
                        parts.append(tail)
                    import re

                    for expr in parts:
                        label = ""
                        m = re.search(
                            r"\bAS\s+([`\"]?)([A-Za-z0-9_]+)\1\s*$",
                            expr,
                            flags=re.IGNORECASE,
                        )
                        if m:
                            label = m.group(2)
                        else:
                            toks = expr.strip().split()
                            if len(toks) >= 2 and toks[-2].upper() != "AS":
                                label = toks[-1].strip('`"')
                            else:
                                dot = expr.rfind(".")
                                if dot != -1:
                                    tail = expr[dot + 1 :].strip()
                                    label = tail.strip('`"')
                                else:
                                    label = toks[-1].strip('`"') if toks else ""
                        label = _clean(label)
                        if label:
                            projection_labels.append(label)
            except Exception:
                projection_labels = []

            def _unqual(s: str) -> str:
                s = s.strip().strip('`"')
                return s.split(".")[-1]

            cols: List[str] = []
            for c in parser_cols:
                rawc = _clean(c)
                if not rawc:
                    continue
                key = _unqual(rawc).lower()
                repl = next(
                    (
                        pl
                        for pl in projection_labels
                        if _unqual(pl).lower() == key
                    ),
                    rawc,
                )
                cols.append(repl)
            if not cols:
                continue

            out_cols: Dict[str, Any] = {}
            for i, c in enumerate(cols, start=1):
                out_cols[c] = {"name": c, "type": "", "index": i}
            out["nodes"][uid] = {
                "metadata": {
                    "database": db,
                    "schema": schema,
                    "name": name,
                    "alias": name,
                    "type": "table",
                },
                "database": db,
                "schema": schema,
                "name": name,
                "alias": name,
                "columns": out_cols,
            }
            added += 1

        if added > 0:
            try:
                p = Path(output_path)
                p.parent.mkdir(parents=True, exist_ok=True)
                with p.open("w", encoding="utf-8") as fh:
                    json.dump(out, fh, ensure_ascii=False)
                logger.info(
                    "✅ Built manifest-SQL catalog.json with %d nodes at %s",
                    added,
                    output_path,
                )
            except Exception as exc:
                logger.warning(
                    "Failed writing manifest-SQL catalog to %s: %s", output_path, exc
                )
                return 0
        return added

    @staticmethod
    def _read_json(path: Path) -> Optional[Dict[str, Any]]:
        if not path.exists():
            return None
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)

def main():
    import argparse
    import sys

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    )

    parser = argparse.ArgumentParser(description="dbt Catalog Builder")
    parser.add_argument(
        "--manifest", required=True, help="Path to manifest.json"
    )
    parser.add_argument(
        "--run-results", required=True, help="Path to run_results.json"
    )
    parser.add_argument(
        "--output", required=True, help="Output path for catalog.json"
    )

    args = parser.parse_args()

    count = DbtCatalogBuilder.build_from_manifest_sql(
        manifest_path=args.manifest,
        run_results_path=args.run_results,
        output_path=args.output,
    )
    print(f"Built catalog with {count} nodes")
    sys.exit(0 if count > 0 else 1)


if __name__ == "__main__":
    main()
