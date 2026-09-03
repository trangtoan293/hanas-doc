import React, {useEffect, useState} from 'react';
import {
  gatewayRecords,
  qualityRecords,
  vaultEntities,
  vaultLinks,
  type JourneyQualityRecord,
  type QualityCheckState,
  type VaultEntity,
  type VaultLink,
  type VaultSatellite,
} from './journeyRecords';
import styles from './styles.module.css';

interface RecordRow {
  id: string;
  value: string;
}

const mobileEvidence: Record<number, RecordRow[]> = {
  0: [
    {id: 'GD-2048', value: 'CoreBank · CDC · 12.800.000'},
    {id: 'KH-01842', value: 'CRM · API · Hà Nội'},
    {id: 'EVT-0905', value: 'MobileBanking · STREAM · checkout'},
  ],
  1: [
    {id: 'GD-2048', value: 'CoreBank CDC → Hanas'},
    {id: 'KH-01842', value: 'CRM API → Hanas'},
    {id: 'EVT-0905', value: 'MobileBanking stream → Hanas'},
  ],
  2: [
    {id: 'GD-2048', value: 'Hợp lệ'},
    {id: 'KH-01842', value: 'Đã đối soát'},
    {id: 'EVT-0905', value: 'Ngoại lệ · thiếu customer_id'},
  ],
};

interface RecordStoryOverlayProps {
  activeStage: number;
  qualityPhase: number;
}

const qualityCheckLabels = ['Kiểu dữ liệu', 'Bắt buộc', 'Đối soát'];
const qualityPassLabels = ['Đúng', 'Đủ', 'Khớp'];

const qualityPhaseCopy = [
  '3 bản ghi vừa được tiếp nhận',
  'Quy tắc 01 · Kiểu dữ liệu — 3/3 hợp lệ',
  'Quy tắc 02 · Bắt buộc — phát hiện 1 trường trống',
  'Quy tắc 03 · Đối soát — bỏ qua bản ghi lỗi',
  '2 đạt chuẩn đi tiếp · 1 ngoại lệ tách riêng',
];

const QUALITY_PHASE_MAX = qualityPhaseCopy.length - 1;
const RULE_COUNT = qualityCheckLabels.length;

function QualityCheckResult({index, state}: {index: number; state: QualityCheckState}): React.JSX.Element {
  const symbol = state === 'pass' ? '✓' : state === 'fail' ? '×' : '—';
  const label = state === 'pass' ? qualityPassLabels[index] : state === 'fail' ? 'Thiếu' : 'Bỏ qua';
  const stateClass = state === 'pass'
    ? styles.qualityCheckPass
    : state === 'fail'
      ? styles.qualityCheckFail
      : styles.qualityCheckSkip;

  return (
    <span className={`${styles.qualityCheckResult} ${stateClass}`}>
      <b>{symbol}</b>
      <small>{label}</small>
    </span>
  );
}

function QualityInputRow({record}: {record: JourneyQualityRecord}): React.JSX.Element {
  return (
    <div className={`${styles.qualityInputRow} ${record.exception ? styles.qualityInputRowException : ''}`}>
      <code>{record.id}</code>
      <span>{record.field}</span>
      <strong>{record.value}</strong>
    </div>
  );
}

function QualityGate({mobile = false, phase}: {mobile?: boolean; phase: number}): React.JSX.Element {
  const safePhase = Math.max(0, Math.min(QUALITY_PHASE_MAX, phase));
  // Quy tắc thứ n hiện ra khi cuộn tới nhịp n; nhịp cuối mới phân luồng đầu ra.
  const rulesRun = Math.min(RULE_COUNT, safePhase);
  const acceptedRecords = qualityRecords.filter((record) => !record.exception);
  const exceptionRecord = qualityRecords.find((record) => record.exception);

  return (
    <div
      className={`${styles.qualityGate} ${mobile ? styles.mobileQualityGate : ''}`}
      data-quality-phase={safePhase}
      data-rules-run={rulesRun}
    >
      <header className={styles.qualityGateSummary}>
        <span>Hanas Quality Gate</span>
        <strong>{qualityPhaseCopy[safePhase]}</strong>
      </header>

      <div className={styles.qualityFlow}>
        <section className={styles.qualityInput}>
          <header>
            <span>Đầu vào</span>
            <strong>3 records</strong>
          </header>
          <div className={styles.qualityInputRows}>
            {qualityRecords.map((record) => <QualityInputRow key={record.id} record={record} />)}
          </div>
        </section>

        <i className={styles.qualityFlowArrow} aria-hidden="true" />

        <section className={styles.qualityGatePanel}>
          <header>
            <span>
              <strong>Quality Gate</strong>
              <small>Kiểm tra trên từng record</small>
            </span>
            <code>{rulesRun}/{RULE_COUNT} RULES</code>
          </header>

          <div className={styles.qualityMatrix}>
            <div className={`${styles.qualityMatrixRow} ${styles.qualityMatrixHeader}`}>
              <span>Record</span>
              {qualityCheckLabels.map((label) => <span key={label}>{label}</span>)}
            </div>
            {qualityRecords.map((record) => (
              <div
                className={`${styles.qualityMatrixRow} ${record.exception ? styles.qualityMatrixRowException : ''}`}
                key={record.id}
              >
                <code>{record.id}</code>
                {record.checks.map((check, index) => (
                  <QualityCheckResult index={index} key={`${record.id}-${qualityCheckLabels[index]}`} state={check} />
                ))}
              </div>
            ))}
          </div>

          {exceptionRecord ? (
            <div className={styles.qualityFailureReason}>
              <i>!</i>
              <span>
                <code>{exceptionRecord.id}.{exceptionRecord.field}</code>
                <small>Không được để trống</small>
              </span>
            </div>
          ) : null}
        </section>

        <i className={`${styles.qualityFlowArrow} ${styles.qualityFlowArrowOutput}`} aria-hidden="true" />

        <section className={styles.qualityOutput}>
          <div className={styles.qualityAcceptedLane}>
            <header>
              <span>Dữ liệu đạt chuẩn</span>
              <strong>{acceptedRecords.length}</strong>
            </header>
            {acceptedRecords.map((record) => (
              <div className={styles.qualityOutputRow} key={record.id}>
                <i>✓</i>
                <code>{record.id}</code>
                <small>Đi tiếp</small>
              </div>
            ))}
          </div>

          {exceptionRecord ? (
            <div className={styles.qualityExceptionLane}>
              <header>
                <span>Ngoại lệ chờ xử lý</span>
                <strong>1</strong>
              </header>
              <div className={styles.qualityOutputRow}>
                <i>!</i>
                <code>{exceptionRecord.id}</code>
                <small>{exceptionRecord.field} = {exceptionRecord.value}</small>
              </div>
            </div>
          ) : null}
        </section>
      </div>
    </div>
  );
}

type VaultAnchor = 'top' | 'right' | 'bottom' | 'left';
type VaultConnectorTone = 'relationship' | 'satellite' | 'linkSatellite';

interface VaultConnectorSpec {
  from: string;
  fromAnchor: VaultAnchor;
  id: string;
  route?: 'aroundTransaction';
  to: string;
  toAnchor: VaultAnchor;
  tone: VaultConnectorTone;
}

interface MeasuredVaultConnector extends VaultConnectorSpec {
  angle: number;
  first: boolean;
  last: boolean;
  length: number;
  segment: number;
  x: number;
  y: number;
}

interface VaultPoint {
  x: number;
  y: number;
}

const vaultConnectorSpecs: VaultConnectorSpec[] = [
  {id: 'customer-account-customer', from: 'hub-customer', fromAnchor: 'right', to: 'link-account-customer', toAnchor: 'left', tone: 'relationship'},
  {id: 'account-customer-account', from: 'link-account-customer', fromAnchor: 'right', to: 'hub-account', toAnchor: 'left', tone: 'relationship'},
  {id: 'account-transaction-account', from: 'hub-account', fromAnchor: 'right', to: 'link-transaction-account', toAnchor: 'left', tone: 'relationship'},
  {id: 'transaction-account-transaction', from: 'link-transaction-account', fromAnchor: 'right', to: 'hub-transaction', toAnchor: 'left', tone: 'relationship'},
  {id: 'transaction-transaction-product', from: 'hub-transaction', fromAnchor: 'right', to: 'link-transaction-product', toAnchor: 'left', tone: 'relationship'},
  {id: 'transaction-product-product', from: 'link-transaction-product', fromAnchor: 'right', to: 'hub-product', toAnchor: 'left', tone: 'relationship'},
  {id: 'transaction-transaction-branch', from: 'hub-transaction', fromAnchor: 'right', to: 'link-transaction-branch', toAnchor: 'left', tone: 'relationship'},
  {id: 'transaction-branch-branch', from: 'link-transaction-branch', fromAnchor: 'right', to: 'hub-branch', toAnchor: 'left', tone: 'relationship'},
  {id: 'account-satellite', from: 'sat-account', fromAnchor: 'bottom', to: 'hub-account', toAnchor: 'top', tone: 'satellite'},
  {id: 'transaction-satellite', from: 'sat-transaction', fromAnchor: 'bottom', to: 'hub-transaction', toAnchor: 'top', tone: 'satellite'},
  {id: 'product-satellite', from: 'sat-product', fromAnchor: 'bottom', to: 'hub-product', toAnchor: 'top', tone: 'satellite'},
  {id: 'customer-satellite', from: 'hub-customer', fromAnchor: 'bottom', to: 'sat-customer', toAnchor: 'top', tone: 'satellite'},
  {id: 'branch-satellite', from: 'hub-branch', fromAnchor: 'bottom', to: 'sat-branch', toAnchor: 'top', tone: 'satellite'},
  {id: 'transaction-product-satellite', from: 'link-transaction-product', fromAnchor: 'bottom', route: 'aroundTransaction', to: 'sat-link', toAnchor: 'top', tone: 'linkSatellite'},
];

function getVaultAnchor(node: HTMLElement, anchor: VaultAnchor): VaultPoint {
  const left = node.offsetLeft;
  const top = node.offsetTop;
  const width = node.offsetWidth;
  const height = node.offsetHeight;

  if (anchor === 'top') return {x: left + width / 2, y: top};
  if (anchor === 'right') return {x: left + width, y: top + height / 2};
  if (anchor === 'bottom') return {x: left + width / 2, y: top + height};
  return {x: left, y: top + height / 2};
}

function isVerticalAnchor(anchor: VaultAnchor): boolean {
  return anchor === 'top' || anchor === 'bottom';
}

// ERD đọc dễ nhất khi đường nối chỉ đi ngang hoặc dọc; đường chéo làm rối sơ đồ.
function routeOrthogonal(
  start: VaultPoint,
  end: VaultPoint,
  fromAnchor: VaultAnchor,
  toAnchor: VaultAnchor,
): VaultPoint[] {
  const fromVertical = isVerticalAnchor(fromAnchor);
  const toVertical = isVerticalAnchor(toAnchor);

  if (fromVertical && toVertical) {
    if (Math.abs(start.x - end.x) < 1) return [start, end];
    const midY = (start.y + end.y) / 2;
    return [start, {x: start.x, y: midY}, {x: end.x, y: midY}, end];
  }

  if (!fromVertical && !toVertical) {
    if (Math.abs(start.y - end.y) < 1) return [start, end];
    const midX = (start.x + end.x) / 2;
    return [start, {x: midX, y: start.y}, {x: midX, y: end.y}, end];
  }

  return fromVertical
    ? [start, {x: start.x, y: end.y}, end]
    : [start, {x: end.x, y: start.y}, end];
}

function measureVaultConnectors(map: HTMLElement): MeasuredVaultConnector[] {
  return vaultConnectorSpecs.flatMap((spec) => {
    const fromNode = map.querySelector<HTMLElement>(`[data-vault-node="${spec.from}"]`);
    const toNode = map.querySelector<HTMLElement>(`[data-vault-node="${spec.to}"]`);
    if (!fromNode || !toNode) return [];

    const start = getVaultAnchor(fromNode, spec.fromAnchor);
    const end = getVaultAnchor(toNode, spec.toAnchor);
    let points = routeOrthogonal(start, end, spec.fromAnchor, spec.toAnchor);

    if (spec.route === 'aroundTransaction') {
      const transactionHub = map.querySelector<HTMLElement>('[data-vault-node="hub-transaction"]');
      const branchLink = map.querySelector<HTMLElement>('[data-vault-node="link-transaction-branch"]');
      if (transactionHub && branchLink) {
        const corridorX = (
          transactionHub.offsetLeft
          + transactionHub.offsetWidth
          + branchLink.offsetLeft
        ) / 2;
        const clearanceY = Math.min(
          end.y - 10,
          transactionHub.offsetTop + transactionHub.offsetHeight + 10,
        );
        points = [
          start,
          {x: corridorX, y: start.y},
          {x: corridorX, y: clearanceY},
          {x: end.x, y: clearanceY},
          end,
        ];
      }
    }

    points = points.filter((point, index) => index === 0
      || Math.abs(point.x - points[index - 1].x) > 0.5
      || Math.abs(point.y - points[index - 1].y) > 0.5);

    return points.slice(0, -1).map((point, segment) => {
      const nextPoint = points[segment + 1];
      const deltaX = nextPoint.x - point.x;
      const deltaY = nextPoint.y - point.y;

      return {
        ...spec,
        angle: Math.atan2(deltaY, deltaX) * 180 / Math.PI,
        first: segment === 0,
        last: segment === points.length - 2,
        length: Math.hypot(deltaX, deltaY),
        segment,
        x: point.x,
        y: point.y,
      };
    });
  });
}

function VaultConnectorLayer({map}: {map: HTMLDivElement | null}): React.JSX.Element {
  const [connectors, setConnectors] = useState<MeasuredVaultConnector[]>([]);

  useEffect(() => {
    if (!map) return undefined;

    let active = true;
    let animationFrame = 0;
    const updateConnectors = () => {
      cancelAnimationFrame(animationFrame);
      animationFrame = requestAnimationFrame(() => {
        if (active) setConnectors(measureVaultConnectors(map));
      });
    };
    const resizeObserver = new ResizeObserver(updateConnectors);

    resizeObserver.observe(map);
    map.querySelectorAll<HTMLElement>('[data-vault-node]').forEach((node) => resizeObserver.observe(node));
    document.fonts?.ready.then(updateConnectors);
    window.addEventListener('resize', updateConnectors);
    updateConnectors();

    return () => {
      active = false;
      cancelAnimationFrame(animationFrame);
      resizeObserver.disconnect();
      window.removeEventListener('resize', updateConnectors);
    };
  }, [map]);

  return (
    <div className={styles.vaultMapEdges} aria-hidden="true">
      {connectors.map((connector) => (
        <i
          className={`${styles.vaultConnector} ${
            connector.tone === 'satellite'
              ? styles.vaultConnectorSatellite
              : connector.tone === 'linkSatellite'
                ? styles.vaultConnectorLinkSatellite
                : ''
          } ${!connector.first ? styles.vaultConnectorWithoutStart : ''} ${
            !connector.last ? styles.vaultConnectorWithoutEnd : ''
          }`}
          data-vault-connector={connector.id}
          data-vault-from={connector.from}
          data-vault-from-anchor={connector.fromAnchor}
          data-vault-to={connector.to}
          data-vault-to-anchor={connector.toAnchor}
          data-vault-segment={connector.segment}
          key={`${connector.id}-${connector.segment}`}
          style={{
            left: connector.x,
            top: connector.y,
            width: connector.length,
            transform: `rotate(${connector.angle}deg)`,
          }}
        />
      ))}
    </div>
  );
}

function VaultSatelliteCard({
  satellite,
  parentKey,
  link = false,
}: {
  satellite: VaultSatellite;
  parentKey: string;
  link?: boolean;
}): React.JSX.Element {
  const displayName = satellite.name.replace(link ? 'SAT_LINK_' : 'SAT_', '');

  return (
    <article className={`${styles.vaultSatellite} ${link ? styles.vaultLinkSatellite : ''}`}>
      <header>
        <span>{link ? 'SAT-LINK' : 'SAT'}</span>
        <code title={satellite.name}>{displayName}</code>
      </header>
      <small className={styles.vaultParentKey}>PARENT · {parentKey}</small>
      <div className={styles.vaultAttributes}>
        {satellite.attributes.map((attribute) => (
          <code key={attribute}>{attribute}</code>
        ))}
      </div>
      <footer>HASHDIFF · LOAD_DTS · RECORD_SOURCE</footer>
    </article>
  );
}

function VaultEntityColumn({entity}: {entity: VaultEntity}): React.JSX.Element {
  return (
    <div className={styles.vaultEntityColumn}>
      <VaultSatelliteCard parentKey={entity.hashKey} satellite={entity.satellite} />
      <i className={styles.vaultVerticalLink} />
      <VaultHubCard entity={entity} />
    </div>
  );
}

function VaultHubCard({entity}: {entity: VaultEntity}): React.JSX.Element {
  // Badge đã ghi loại thẻ nên bỏ tiền tố, giống cách SAT và LINK rút gọn tên.
  const displayName = entity.hub.replace('HUB_', '');

  return (
    <article className={styles.vaultHub}>
      <header>
        <span>HUB</span>
        <code title={entity.hub}>{displayName}</code>
      </header>
      <small className={styles.vaultParentKey}>HK · {entity.hashKey}</small>
      <small className={styles.vaultParentKey}>BK · {entity.businessKey}</small>
      <footer>LOAD_DTS · RECORD_SOURCE</footer>
    </article>
  );
}

function VaultLinkCard({link, showSatellite = true}: {link: VaultLink; showSatellite?: boolean}): React.JSX.Element {
  const displayName = link.name
    .replace('LINK_TRANSACTION_', 'TXN_')
    .replace('LINK_ACCOUNT_CUSTOMER', 'ACCT_CUSTOMER')
    .replace('LINK_', '');

  return (
    <div className={styles.vaultLinkGroup}>
      <article className={styles.vaultLinkCard}>
        <header>
          <span>LINK</span>
          <code title={link.name}>{displayName}</code>
        </header>
        <small className={styles.vaultLinkHash}>HK · {link.hashKey}</small>
        <div>
          {link.hubKeys.map((hubKey) => <code key={hubKey}>{hubKey}</code>)}
        </div>
        <footer>LOAD_DTS · RECORD_SOURCE</footer>
      </article>
      {showSatellite && link.satellite ? (
        <>
          <i className={styles.vaultVerticalLink} />
          <VaultSatelliteCard link parentKey={link.hashKey} satellite={link.satellite} />
        </>
      ) : null}
    </div>
  );
}

function DataVaultDiagram({mobile = false}: {mobile?: boolean}): React.JSX.Element {
  if (mobile) {
    return (
      <div className={styles.mobileVaultDiagram}>
        <VaultDiagramHeader />
        <div className={styles.vaultEntityGrid}>
          {vaultEntities.map((entity) => <VaultEntityColumn entity={entity} key={entity.hub} />)}
        </div>
        <div className={styles.vaultLinkGrid}>
          {vaultLinks.map((link) => <VaultLinkCard key={link.name} link={link} />)}
        </div>
      </div>
    );
  }

  return <DesktopDataVaultDiagram />;
}

function DesktopDataVaultDiagram(): React.JSX.Element {
  const [map, setMap] = useState<HTMLDivElement | null>(null);
  const [customer, account, transaction, product, branch] = vaultEntities;
  const [accountCustomer, transactionAccount, transactionProduct, transactionBranch] = vaultLinks;

  return (
    <div className={styles.vaultDiagram}>
      <VaultDiagramHeader />
      <div className={styles.vaultMap} ref={setMap}>
        <VaultConnectorLayer map={map} />

        <div className={`${styles.vaultMapNode} ${styles.vaultSatAccount}`} data-vault-node="sat-account">
          <VaultSatelliteCard parentKey={account.hashKey} satellite={account.satellite} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultSatTransaction}`} data-vault-node="sat-transaction">
          <VaultSatelliteCard parentKey={transaction.hashKey} satellite={transaction.satellite} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultSatProduct}`} data-vault-node="sat-product">
          <VaultSatelliteCard parentKey={product.hashKey} satellite={product.satellite} />
        </div>

        <div className={`${styles.vaultMapNode} ${styles.vaultHubCustomer}`} data-vault-node="hub-customer"><VaultHubCard entity={customer} /></div>
        <div className={`${styles.vaultMapNode} ${styles.vaultLinkAccountCustomer}`} data-vault-node="link-account-customer">
          <VaultLinkCard link={accountCustomer} showSatellite={false} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultHubAccount}`} data-vault-node="hub-account"><VaultHubCard entity={account} /></div>
        <div className={`${styles.vaultMapNode} ${styles.vaultLinkTransactionAccount}`} data-vault-node="link-transaction-account">
          <VaultLinkCard link={transactionAccount} showSatellite={false} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultHubTransaction}`} data-vault-node="hub-transaction"><VaultHubCard entity={transaction} /></div>

        <div className={`${styles.vaultMapNode} ${styles.vaultLinkTransactionProduct}`} data-vault-node="link-transaction-product">
          <VaultLinkCard link={transactionProduct} showSatellite={false} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultHubProduct}`} data-vault-node="hub-product"><VaultHubCard entity={product} /></div>
        <div className={`${styles.vaultMapNode} ${styles.vaultLinkTransactionBranch}`} data-vault-node="link-transaction-branch">
          <VaultLinkCard link={transactionBranch} showSatellite={false} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultHubBranch}`} data-vault-node="hub-branch"><VaultHubCard entity={branch} /></div>

        <div className={`${styles.vaultMapNode} ${styles.vaultSatCustomer}`} data-vault-node="sat-customer">
          <VaultSatelliteCard parentKey={customer.hashKey} satellite={customer.satellite} />
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultSatLink}`} data-vault-node="sat-link">
          {transactionProduct.satellite ? (
            <VaultSatelliteCard link parentKey={transactionProduct.hashKey} satellite={transactionProduct.satellite} />
          ) : null}
        </div>
        <div className={`${styles.vaultMapNode} ${styles.vaultSatBranch}`} data-vault-node="sat-branch">
          <VaultSatelliteCard parentKey={branch.hashKey} satellite={branch.satellite} />
        </div>
      </div>
    </div>
  );
}

function VaultDiagramHeader(): React.JSX.Element {
  return (
    <header className={styles.vaultDiagramHeader}>
      <span>
        <i className={styles.vaultLegendHub} /> HUB
        <i className={styles.vaultLegendSat} /> SAT
        <i className={styles.vaultLegendLink} /> LINK
        <i className={styles.vaultLegendLinkSat} /> SAT-LINK
      </span>
    </header>
  );
}

export default function RecordStoryOverlay({activeStage, qualityPhase}: RecordStoryOverlayProps): React.JSX.Element {
  return (
    <div className={styles.recordStory} aria-hidden="true">
      <div className={`${styles.gatewayRecordLayer} ${activeStage === 1 ? styles.recordLayerActive : ''}`}>
        <header className={styles.gatewayHeader}>
          <span className={styles.gatewayMark}>H</span>
          <span className={styles.gatewayIdentity}>
            <strong>Hanas Capture</strong>
            <small>Batch + real-time</small>
          </span>
          <span className={styles.gatewayStatus}>Nhận</span>
        </header>
        <div className={styles.gatewayRecordStack}>
          {gatewayRecords.map((record) => (
            <div className={styles.gatewayRecord} key={record.id}>
              <span>{record.source}</span>
              <code>{record.id}</code>
              <small>{record.event}</small>
            </div>
          ))}
        </div>
        <footer className={styles.gatewayFooter}>
          <span><i /> 3 bản ghi đang hội tụ</span>
        </footer>
      </div>

      <div className={`${styles.qualityRecordLayer} ${activeStage === 2 ? styles.recordLayerActive : ''}`}>
        <QualityGate phase={qualityPhase} />
      </div>

      <div className={`${styles.vaultDiagramLayer} ${activeStage === 3 ? styles.recordLayerActive : ''}`}>
        <DataVaultDiagram />
      </div>
    </div>
  );
}

export function MobileRecordEvidence({stage}: {stage: number}): React.JSX.Element | null {
  if (stage === 2) {
    return (
      <div aria-label="Minh họa kiểm tra và phân loại chất lượng dữ liệu">
        <QualityGate mobile phase={QUALITY_PHASE_MAX} />
      </div>
    );
  }

  if (stage === 3) {
    return (
      <div aria-label="Mô hình Data Vault 2.0">
        <DataVaultDiagram mobile />
      </div>
    );
  }

  const records = mobileEvidence[stage];
  if (!records) return null;

  return (
    <div className={styles.mobileRecordEvidence} aria-label="Ví dụ dữ liệu minh họa">
      <span>Dữ liệu minh họa</span>
      {records.map((record) => (
        <div key={record.id}>
          <code>{record.id}</code>
          <small>{record.value}</small>
        </div>
      ))}
    </div>
  );
}
