export interface JourneySourceRecord {
  id: string;
  values: [string, string];
}

export interface JourneySource {
  accent: string;
  columns: [string, string, string];
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
    glyph: 'CB',
    mode: 'Oracle',
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
    glyph: 'LOS',
    mode: 'SQL Server',
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
    glyph: 'CRM',
    mode: 'PostgreSQL',
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
    glyph: 'MB',
    mode: 'S3',
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
