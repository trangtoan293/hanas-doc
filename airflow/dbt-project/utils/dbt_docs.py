from __future__ import annotations

import json
import logging
import os
import subprocess
from pathlib import Path
from typing import Any, Dict, Optional

from .dbt_catalog import DbtCatalogBuilder


logger = logging.getLogger(__name__)


class DbtDocsGenerator:
    def __init__(
        self,
        dbt_command: str = "dbt",
        project_dir: str | Path = ".",
        target: str = "dev",
        target_dir: str | Path = "target",
        profiles_dir: Optional[str | Path] = None,
    ) -> None:
        self.dbt_command = dbt_command
        self.project_dir = Path(project_dir).resolve()
        self.target = target
        self.target_dir = Path(target_dir).resolve()
        self.profiles_dir = Path(profiles_dir).resolve() if profiles_dir else self.project_dir

    def generate(self) -> Dict[str, Any]:
        self.target_dir.mkdir(parents=True, exist_ok=True)

        env = os.environ.copy()
        env.setdefault("DBT_PROJECT_DIR", str(self.project_dir))
        env.setdefault("DBT_PROFILES_DIR", str(self.profiles_dir))
        env.setdefault("DBT_TARGET_PATH", str(self.target_dir))

        manifest_path = self.target_dir / "manifest.json"
        run_results_path = self.target_dir / "run_results.json"
        catalog_path = self.target_dir / "catalog.json"

        backup_path = self.target_dir / "run_results_backup.json"
        if run_results_path.exists():
            try:
                import shutil

                shutil.copyfile(run_results_path, backup_path)
            except Exception:
                pass

        cmd = [
            self.dbt_command,
            "docs",
            "generate",
            "--target",
            self.target,
        ]
        logger.info("Running docs command via subprocess: %s", " ".join(cmd))
        proc = subprocess.Popen(
            cmd,
            cwd=self.project_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            env=env,
        )
        assert proc.stdout is not None
        for line in proc.stdout:
            print(line, end="")
        return_code = proc.wait()

        if return_code != 0:
            logger.warning("dbt docs generate failed with return code: %s", return_code)

        node_count = 0
        fallback_used = False
        if catalog_path.exists():
            try:
                with catalog_path.open() as f:
                    cat = json.load(f)
                node_count = len(cat.get("nodes", {}))
                logger.info("📊 catalog.json generated with %d nodes", node_count)
                if node_count == 0:
                    logger.error(
                        "⚠️  catalog.json is EMPTY! dbt couldn't introspect any tables."
                    )
                    logger.error(
                        "    Check: 1) Tables exist in metastore, 2) Hive connection works, 3) Correct catalog/schema"
                    )
                    fallback_used = self._run_manifest_fallback(
                        manifest_path, run_results_path, catalog_path
                    )
            except Exception as exc:
                logger.warning("Could not parse catalog.json: %s", exc)
                fallback_used = self._run_manifest_fallback(
                    manifest_path, run_results_path, catalog_path
                )
        else:
            logger.warning("catalog.json not generated!")
            fallback_used = self._run_manifest_fallback(
                manifest_path, run_results_path, catalog_path
            )

        if backup_path.exists():
            try:
                import shutil

                shutil.copyfile(backup_path, run_results_path)
            except Exception:
                pass

        return {
            "return_code": return_code,
            "catalog_path": str(catalog_path),
            "fallback_used": fallback_used,
        }

    def _run_manifest_fallback(
        self,
        manifest_path: Path,
        run_results_path: Path,
        catalog_path: Path,
    ) -> bool:
        built = DbtCatalogBuilder.build_from_manifest_sql(
            manifest_path=str(manifest_path),
            run_results_path=str(run_results_path),
            output_path=str(catalog_path),
        )
        logger.info("Fallback manifest-SQL catalog builder added %d nodes", built)
        return built > 0
