export interface JourneySourceRecord {
  id: string;
  values: [string, string];
}

export interface JourneySource {
  accent: string;
  columns: [string, string, string];
  domain: string;
  glyph: string;
  mode: string;
  name: string;
  records: JourneySourceRecord[];
  updatedAt: string;
}

export const journeySources: JourneySource[] = [
  {
    accent: '#70c8ec',
    columns: ['transaction_id', 'amount', 'time'],
    domain: 'Tài khoản & giao dịch',
    glyph: 'CB',
    mode: 'CDC',
    name: 'CoreBank',
    records: [
      {id: 'GD-2048', values: ['12.800.000', '10:42:16']},
      {id: 'GD-2049', values: ['4.200.000', '10:43:02']},
    ],
    updatedAt: '10:43:08',
  },
  {
    accent: '#82d4bd',
    columns: ['application_id', 'amount', 'status'],
    domain: 'Hồ sơ tín dụng',
    glyph: 'LOS',
    mode: 'BATCH',
    name: 'LOS',
    records: [
      {id: 'HS-7412', values: ['850.000.000', 'Giải ngân']},
      {id: 'HS-7413', values: ['320.000.000', 'Chờ duyệt']},
    ],
    updatedAt: '10:40:00',
  },
  {
    accent: '#dfa66f',
    columns: ['customer_id', 'city', 'tier'],
    domain: 'Khách hàng & phân khúc',
    glyph: 'CRM',
    mode: 'API',
    name: 'CRM',
    records: [
      {id: 'KH-01842', values: ['Hà Nội', 'Gold']},
      {id: 'KH-01843', values: ['Đà Nẵng', 'Standard']},
    ],
    updatedAt: '10:43:11',
  },
  {
    accent: '#b2c8d8',
    columns: ['event_id', 'event', 'customer_id'],
    domain: 'Sự kiện ứng dụng',
    glyph: 'MB',
    mode: 'STREAM',
    name: 'MobileBanking',
    records: [
      {id: 'EVT-0904', values: ['page_view', 'KH-01842']},
      {id: 'EVT-0905', values: ['checkout', 'null']},
    ],
    updatedAt: '10:43:14',
  },
];

export const gatewayRecords = [
  {id: 'GD-2048', source: 'CB', event: 'payment'},
  {id: 'KH-01842', source: 'CRM', event: 'customer'},
  {id: 'EVT-0905', source: 'MB', event: 'checkout'},
];

export type QualityCheckState = 'pass' | 'fail' | 'skip';

export interface JourneyQualityRecord {
  checks: [QualityCheckState, QualityCheckState, QualityCheckState];
  exception: boolean;
  field: string;
  id: string;
  value: string;
}

export const qualityRecords: JourneyQualityRecord[] = [
  {
    checks: ['pass', 'pass', 'pass'],
    exception: false,
    field: 'amount',
    id: 'GD-2048',
    value: '12.800.000',
  },
  {
    checks: ['pass', 'pass', 'pass'],
    exception: false,
    field: 'customer_id',
    id: 'KH-01842',
    value: 'KH-01842',
  },
  {
    checks: ['pass', 'fail', 'skip'],
    exception: true,
    field: 'customer_id',
    id: 'EVT-0905',
    value: 'null',
  },
];

export interface VaultSatellite {
  attributes: string[];
  name: string;
}

export interface VaultEntity {
  businessKey: string;
  hashKey: string;
  hub: string;
  satellite: VaultSatellite;
}

export interface VaultLink {
  hashKey: string;
  hubKeys: [string, string];
  name: string;
  satellite?: VaultSatellite;
}

export const vaultEntities: VaultEntity[] = [
  {
    businessKey: 'customer_id',
    hashKey: 'customer_hk',
    hub: 'HUB_CUSTOMER',
    satellite: {
      name: 'SAT_CUSTOMER_PROFILE',
      attributes: ['full_name', 'segment', 'customer_status'],
    },
  },
  {
    businessKey: 'account_number',
    hashKey: 'account_hk',
    hub: 'HUB_ACCOUNT',
    satellite: {
      name: 'SAT_ACCOUNT_DETAIL',
      attributes: ['account_type', 'currency', 'account_status'],
    },
  },
  {
    businessKey: 'transaction_id',
    hashKey: 'transaction_hk',
    hub: 'HUB_TRANSACTION',
    satellite: {
      name: 'SAT_TRANSACTION_DETAIL',
      attributes: ['transaction_type', 'amount', 'transaction_status'],
    },
  },
  {
    businessKey: 'product_id',
    hashKey: 'product_hk',
    hub: 'HUB_PRODUCT',
    satellite: {
      name: 'SAT_PRODUCT_DETAIL',
      attributes: ['product_name', 'category', 'unit_price'],
    },
  },
  {
    businessKey: 'branch_code',
    hashKey: 'branch_hk',
    hub: 'HUB_BRANCH',
    satellite: {
      name: 'SAT_BRANCH_DETAIL',
      attributes: ['branch_name', 'region', 'branch_type'],
    },
  },
];

export const vaultLinks: VaultLink[] = [
  {
    name: 'LINK_ACCOUNT_CUSTOMER',
    hashKey: 'account_customer_hk',
    hubKeys: ['account_hk', 'customer_hk'],
  },
  {
    name: 'LINK_TRANSACTION_ACCOUNT',
    hashKey: 'transaction_account_hk',
    hubKeys: ['transaction_hk', 'account_hk'],
  },
  {
    name: 'LINK_TRANSACTION_PRODUCT',
    hashKey: 'transaction_product_hk',
    hubKeys: ['transaction_hk', 'product_hk'],
    satellite: {
      name: 'SAT_LINK_TXN_PRODUCT',
      attributes: ['quantity', 'unit_price', 'discount_amount'],
    },
  },
  {
    name: 'LINK_TRANSACTION_BRANCH',
    hashKey: 'transaction_branch_hk',
    hubKeys: ['transaction_hk', 'branch_hk'],
  },
];
