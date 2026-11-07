import useDocusaurusContext from '@docusaurus/useDocusaurusContext';

// All landing page text, one object per locale. Claims follow docs/ and PRODUCT.md:
// no customers, benchmarks or roadmap. Numbers inside the illustrations are sample data.

const vi = {
  meta: {
    title: 'Nền tảng dữ liệu doanh nghiệp với Ontology và AI agent',
    description:
      'Hanas Data Platform đọc dữ liệu tại nguồn, mô hình hoá nghiệp vụ bằng Ontology và để AI agent Kapas trả lời bằng tiếng Việt, ngay trên hạ tầng của bạn.',
    keywords:
      'nền tảng dữ liệu doanh nghiệp, data platform, AI agent, Ontology, hỏi đáp dữ liệu bằng AI, lakehouse, Apache Iceberg, data catalog, on-premise',
    schemaDescription:
      'Nền tảng dữ liệu doanh nghiệp: truy vấn tại nguồn, lakehouse Apache Iceberg, dbt Studio, Hanas Catalog, Ontology và AI agent Kapas, triển khai on-premise hoặc private cloud.',
  },
  hero: {
    title: 'Một nền\u00a0tảng.',
    titleAccent: 'Mọi hành\u00a0trình dữ\u00a0liệu.',
    subtitle:
      'Từ kết nối nguồn dữ liệu đến xây dựng pipeline, phân tích và quản\u00a0trị\u00a0— tất cả trong một workspace thống nhất. Để đội ngũ tập trung tạo ra giá trị, thay vì kết nối các công cụ rời rạc.',
    primary: 'Đặt lịch demo',
    secondary: 'Xem tài liệu',
    board: {
      aria: 'Kiến trúc Hanas Data Platform: nguồn dữ liệu đi vào lõi query engine và Iceberg lakehouse, qua các lớp xử lý, quản trị và Ontology, rồi đến AI agent Kapas, BI, ứng dụng và người dùng',
      sourcesTitle: 'Nguồn dữ liệu',
      sources: [
        {name: 'Cơ sở dữ liệu', meta: 'JDBC', items: 'Oracle, SQL Server, PostgreSQL, MySQL'},
        {name: 'Kho dữ liệu sẵn có', meta: 'Đọc tại nguồn', items: 'Snowflake và lakehouse hiện tại'},
        {name: 'Object storage', meta: 'S3', items: 'CSV, JSON, Parquet'},
        {name: 'Ứng dụng nghiệp vụ', meta: 'REST API', items: 'Core banking, CRM, ERP'},
      ],
      platform: 'Hanas Data Platform',
      platformMeta: 'Kubernetes',
      governTitle: 'Danh tính & quản trị',
      govern: [
        {name: 'Keycloak SSO', detail: 'Group, role, token exchange'},
        {name: 'Hanas Catalog', detail: 'Owner, glossary, tag, lineage'},
        {name: 'Quyền theo người dùng', detail: 'Kiểm tra trên từng truy vấn'},
      ],
      processTitle: 'Xử lý',
      process: [
        {name: 'Ingestion', detail: 'Nạp theo lịch, có checkpoint'},
        {name: 'dbt Studio', detail: 'Model và test trên trình duyệt'},
        {name: 'Pipeline', detail: 'Điều phối theo lịch'},
        {name: 'Compute', detail: 'PySpark và notebook'},
      ],
      coreTitle: 'Query engine',
      coreMeta: 'Một điểm truy vấn cho mọi nguồn',
      lakeTitle: 'Apache Iceberg lakehouse',
      zones: [
        {name: 'Bronze', detail: 'dữ liệu thô'},
        {name: 'Silver', detail: 'đã chuẩn hoá'},
        {name: 'Gold', detail: 'mart nghiệp vụ'},
      ],
      features: ['Time travel', 'Schema evolution', 'Snapshot'],
      storage: 'Object storage',
      semanticTitle: 'Ngữ nghĩa cho AI agent',
      ontology: {name: 'Ontology', detail: 'Object type, quan hệ và metric có phiên bản'},
      ontologyItems: ['Khách hàng', 'Tài khoản', 'Giao dịch'],
      consumersTitle: 'Sử dụng',
      consumers: [
        {name: 'AI agent Kapas', meta: 'Ontology + quyền người hỏi', items: 'Hỏi bằng tiếng Việt, nhận số liệu có nguồn'},
        {name: 'Analytics & BI', meta: 'JDBC · ODBC', items: 'Superset, Power BI, Tableau'},
        {name: 'Ứng dụng & code', meta: 'REST · Arrow Flight', items: 'API nội bộ, PySpark, notebook'},
        {name: 'Người dùng nghiệp vụ', meta: 'Hanas Console', items: 'SQL Editor, dashboard, khám phá Ontology'},
      ],
    },
    pause: 'Tạm dừng hiệu ứng',
    play: 'Chạy hiệu ứng',
  },
  journey: {
    ariaLabel: 'Hành trình dữ liệu trên Hanas',
    eyebrow: 'Dữ liệu đi qua Hanas thế nào',
    scrollCue: 'Cuộn để xem dữ liệu đi tiếp',
    visualLabel: 'HANAS / LUỒNG DỮ LIỆU',
    step: 'Bước',
    of: 'trên',
    labels: ['Hiện trạng', 'Kết nối', 'Ontology', 'AI Agent', 'Khai thác'],
    chapters: [
      {
        title: 'Dữ\u00a0liệu rải\u00a0rác, báo\u00a0cáo chậm',
        description: 'Mỗi hệ thống giữ một phần dữ liệu, nên mỗi phòng ban báo cáo một con số khác nhau.',
        outcome: 'Báo cáo rời rạc · Đối soát bằng tay',
      },
      {
        title: 'Đọc dữ\u00a0liệu ngay tại\u00a0nguồn',
        description: 'Truy vấn trực tiếp Oracle, SQL Server, PostgreSQL và object storage. Chỉ nạp vào Iceberg khi cần lưu bản sao.',
        outcome: 'Query engine · Apache Iceberg · dbt',
      },
      {
        title: 'Biến bảng dữ\u00a0liệu thành khái\u00a0niệm nghiệp\u00a0vụ',
        description: 'Định nghĩa khách hàng, tài khoản, giao dịch và chỉ số một lần, rồi gắn với dữ liệu thật.',
        outcome: 'Object type · Quan hệ · Metric',
      },
      {
        title: 'Hỏi một câu, nhận câu trả\u00a0lời có nguồn',
        description: 'Kapas đọc Ontology để hiểu câu hỏi và truy vấn bằng chính quyền của bạn. Bạn không cần viết SQL.',
        outcome: 'Kapas · Ontology · Quyền của người hỏi',
      },
      {
        title: 'Một con\u00a0số chung cho cả công\u00a0ty',
        description: 'Kapas, dashboard và ứng dụng nội bộ cùng đọc định nghĩa chỉ số trong Ontology.',
        outcome: 'Kapas · Superset · API',
      },
    ],
  },
  sources: {
    domains: ['Tài khoản & giao dịch', 'Hồ sơ tín dụng', 'Khách hàng & phân khúc', 'Sự kiện ứng dụng'],
    receiving: 'Đang nhận dữ liệu',
  },
  gateway: {
    name: 'Query engine',
    mode: 'Đọc tại nguồn',
    status: 'Nhận',
    footer: '3 bản ghi đang hội tụ',
  },
  sample: {
    label: 'Dữ liệu minh họa',
    rows: [
      [
        {id: 'GD-2048', value: 'CoreBank · Oracle · 12.800.000'},
        {id: 'KH-01842', value: 'CRM · PostgreSQL · Hà Nội'},
        {id: 'EVT-0905', value: 'MobileBanking · object storage'},
      ],
      [
        {id: 'GD-2048', value: 'CoreBank → query engine'},
        {id: 'KH-01842', value: 'CRM → query engine'},
        {id: 'EVT-0905', value: 'MobileBanking → Iceberg'},
      ],
    ],
    ontologyAria: 'Minh họa Ontology: đối tượng, quan hệ và chỉ số',
    agentAria: 'Minh họa Kapas trả lời câu hỏi',
  },
  ontology: {
    subtitle: 'Ngân hàng bán lẻ · dữ liệu minh họa',
    badge: 'v3 · Đã publish',
    objects: [
      {name: 'Khách hàng', properties: ['ma_kh', 'phan_khuc']},
      {name: 'Tài khoản', properties: ['so_tk', 'loai_tk']},
      {name: 'Chi nhánh', properties: ['ma_cn', 'khu_vuc']},
      {name: 'Giao dịch', properties: ['so_tien', 'kenh']},
    ],
    links: ['sở hữu', 'phát sinh', 'thực hiện tại', 'mở tại'],
    metrics: ['Doanh thu thuần', 'Khách hàng hoạt động'],
    bound: 'Gắn với dataset',
  },
  agent: {
    subtitle: 'Agent phân tích · dữ liệu minh họa',
    badge: 'Quyền của bạn',
    question: 'Doanh thu thuần tháng này của miền Bắc so với tháng trước thế nào?',
    steps: [
      {label: 'Hiểu câu hỏi qua Ontology', detail: 'Giao dịch → Chi nhánh.khu_vuc'},
      {label: 'Lấy định nghĩa chỉ số', detail: 'metric: Doanh thu thuần · v3'},
      {label: 'Chạy truy vấn qua query engine', detail: 'dưới danh tính của bạn'},
    ],
    answer: {
      before: 'Doanh thu thuần miền Bắc tháng này đạt ',
      value: '41,2 tỷ',
      middle: ', tăng ',
      change: '6,4%',
      after: ' so với tháng trước. Chi nhánh Hà Nội đóng góp nhiều nhất.',
    },
    source: 'Theo metric Doanh thu thuần · Ontology v3',
  },
  dashboard: {
    title: 'Tổng quan điều hành',
    scope: 'Hôm nay · Toàn doanh nghiệp',
    synced: 'Đã đồng bộ',
    kpis: [
      {label: 'Doanh thu thuần', value: '128,4 tỷ', delta: '↗ 18,6% so với kỳ trước'},
      {label: 'Giao dịch', value: '2,48 triệu', delta: '↗ 7,2% so với kỳ trước'},
      {label: 'Khách hàng hoạt động', value: '184.920', delta: '↗ 4,8% so với kỳ trước'},
    ],
    trendKicker: 'Doanh thu',
    trendTitle: 'Xu hướng theo tháng',
    trendDelta: '+24,8%',
    months: ['T1', 'T2', 'T3', 'T4', 'T5', 'T6'],
    volumeKicker: 'Giao dịch',
    volumeTitle: 'Giao dịch theo kênh',
    volumePill: '12 tháng',
    valid: 'Hợp lệ',
    validValue: '99,97%',
    exceptions: 'Ngoại lệ',
    exceptionsValue: '0,03%',
    footer: ['Kỳ dữ liệu: tháng này', '4 nguồn', 'Cập nhật: 10:45'],
    details: 'Xem chi tiết →',
  },
  grid: {
    titleLines: ['Công cụ riêng cho từng\u00a0đội', 'chung một bộ\u00a0quyền'],
    learnMore: 'Tìm hiểu',
    cards: [
      {title: 'Ontology & Kapas AI', description: 'Định nghĩa nghiệp vụ một lần trong Ontology, rồi hỏi Kapas bằng tiếng Việt.'},
      {title: 'Kết nối & nạp dữ liệu', description: 'Truy vấn ngay tại nguồn và nạp vào Iceberg theo lịch khi cần lưu lại.'},
      {title: 'Lakehouse mở', description: 'Lưu bảng bằng Apache Iceberg trên hạ tầng của bạn, nên đổi công cụ xử lý mà không phải chuyển dữ liệu.'},
      {title: 'Biến đổi & điều phối', description: 'Viết và kiểm thử dbt model ngay trên trình duyệt, rồi lên lịch chạy bằng Pipeline.'},
      {title: 'Quản trị & bảo mật', description: 'Đăng nhập một lần. Mỗi truy vấn được kiểm tra theo quyền của chính người gửi, đến từng bảng.'},
      {title: 'Truy vấn & BI', description: 'Viết SQL, dựng dashboard Superset hoặc kết nối Power BI và Tableau qua JDBC/ODBC.'},
    ],
  },
  tabs: {
    titleLines: ['Bắt đầu từ một\u00a0phần', 'rồi mở\u00a0rộng dần'],
    intro: 'Phần làm sau dùng lại dữ liệu, quyền và định nghĩa đã có từ phần làm trước.',
    listAria: 'Các cách bắt đầu với Hanas',
    flowTitle: 'Luồng xử lý',
    items: [
      {
        label: 'Ontology & AI',
        eyebrow: 'Cho quản lý và kinh doanh',
        title: 'Tự tra số\u00a0liệu bằng tiếng\u00a0Việt',
        description: 'Định nghĩa "doanh thu" hay "khách hàng hoạt động" một lần trong Ontology. Kapas trả lời theo đúng công thức đó, nên con số khớp với báo cáo và bạn không phải chờ ai viết SQL.',
        bullets: ['Kapas truy vấn bằng quyền của chính người hỏi', 'Định nghĩa có phiên bản, publish rồi mới áp dụng', 'Dùng model qua API hoặc tự host trong mạng nội bộ'],
        flow: ['Bảng dữ liệu', 'Định nghĩa trong Ontology', 'Câu trả lời từ Kapas'],
      },
      {
        label: 'Nền tảng dữ liệu',
        eyebrow: 'Cho đội dữ liệu',
        title: 'Truy vấn ngay trên hệ\u00a0thống đang\u00a0chạy',
        description: 'Kết nối Oracle, SQL Server hay PostgreSQL rồi truy vấn tại chỗ mà chưa cần chuyển dữ liệu đi đâu. Bảng nào cần giữ lịch sử hoặc dùng nhiều thì nạp vào Iceberg sau.',
        bullets: ['Ghép bảng từ nhiều hệ thống trong một câu SQL', 'Lần nạp lỗi chạy tiếp từ checkpoint cuối', 'Viết và test dbt model ngay trên trình duyệt'],
        flow: ['Hệ thống đang chạy', 'Query engine', 'Bảng Iceberg khi cần lưu'],
      },
      {
        label: 'Quản trị & tin cậy',
        eyebrow: 'Cho IT và bảo mật',
        title: 'Mỗi người chỉ thấy dữ\u00a0liệu mình được\u00a0xem',
        description: 'Nhân viên chi nhánh xem khách hàng của chi nhánh mình, còn số điện thoại bị che với người không có quyền. Quy tắc này áp dụng như nhau trong SQL Editor, dashboard và Kapas.',
        bullets: ['Một tài khoản Keycloak cho mọi ứng dụng', 'Lọc hàng và che cột bằng policy', 'Catalog cho biết bảng của ai, lấy từ đâu'],
        flow: ['Đăng nhập một lần', 'Kiểm tra quyền trên từng truy vấn', 'Dữ liệu đúng phạm vi'],
      },
    ],
  },
  useCases: {
    titleLines: ['Từ câu\u00a0hỏi nhanh', 'đến pipeline hằng\u00a0ngày'],
    railAria: 'Các bài toán doanh nghiệp tiêu biểu',
    more: 'Xem tài liệu',
    items: [
      {category: 'Phân tích dữ liệu', title: 'Hỏi đáp dữ liệu với AI', description: 'Hỏi Kapas như hỏi một đồng nghiệp. Câu trả lời dựa trên chỉ số đội bạn đã định nghĩa.'},
      {category: 'Ngân hàng & tài chính', title: 'Customer 360', description: 'Gộp khách hàng, tài khoản và giao dịch thành một hồ sơ trong Ontology.'},
      {category: 'BI tự phục vụ', title: 'SQL và dashboard tự phục vụ', description: 'Tự truy vấn, lưu view và dựng dashboard mà không phải chờ IT.'},
      {category: 'Vận hành dữ liệu', title: 'Pipeline truy vết được', description: 'Lên lịch các bước SQL và dbt. Khi có lỗi, bạn thấy ngay bước nào hỏng.'},
    ],
  },
  faq: {
    titleLines: ['Câu\u00a0hỏi thường\u00a0gặp', 'về Hanas'],
    link: 'Đọc giới thiệu nền tảng',
    items: [
      {
        question: 'Hanas có triển khai on-premise được không?',
        answer: 'Có. Hanas chạy trên Kubernetes trong trung tâm dữ liệu hoặc private cloud của bạn. Dữ liệu không rời mạng nội bộ.',
      },
      {
        question: 'Câu trả lời của Kapas có đáng tin không?',
        answer: 'Kapas tính trên chỉ số đã định nghĩa trong Ontology, nên dùng cùng công thức với báo cáo. Kết quả quan trọng vẫn nên đối chiếu với nguồn.',
      },
      {
        question: 'Có dùng được mô hình AI tự host không?',
        answer: 'Có. Kapas dùng được model qua API hoặc model tự host như vLLM và Ollama. Truy vấn dữ liệu vẫn chạy bằng token của người hỏi.',
      },
      {
        question: 'Có kết nối được hệ thống đang có không?',
        answer: 'Được. Hanas đọc Oracle, SQL Server, PostgreSQL, MySQL, Snowflake và object storage. Ứng dụng khác lấy dữ liệu qua JDBC, ODBC, Arrow Flight hoặc REST API.',
      },
      {
        question: 'Dữ liệu được phân quyền thế nào?',
        answer: 'Người dùng đăng nhập một lần qua Keycloak. Query engine kiểm tra quyền trên từng truy vấn theo danh tính của người gửi.',
      },
      {
        question: 'Có bị khoá vào một nhà cung cấp không?',
        answer: 'Không. Dữ liệu nằm trên hạ tầng của bạn, ở định dạng mở Apache Iceberg. dbt, Spark, Superset và Keycloak đều là mã nguồn mở.',
      },
      {
        question: 'Nên bắt đầu từ đâu?',
        answer: 'Chọn một bài toán có giá trị rõ ràng và triển khai theo từng pha. Kết quả pha đầu cho biết nên mở rộng tiếp ở đâu.',
      },
    ],
  },
  cta: {
    titleLines: ['Xem Hanas chạy', 'trên dữ\u00a0liệu của bạn'],
    body: 'Đặt một buổi trao đổi để chọn bài toán đầu tiên và phạm vi triển khai.',
    action: 'Đặt lịch demo',
    actionAria: 'Đặt lịch demo qua email thunnv@katalyst.vn',
    mailSubject: 'Yêu cầu demo Hanas Data Platform',
    roadmapTitle: 'Lộ trình triển khai',
    steps: [
      {title: 'Khảo sát', description: 'Rà hạ tầng và chọn bài toán ưu tiên'},
      {title: 'Thiết kế', description: 'Chốt kiến trúc và phạm vi từng pha'},
      {title: 'Vận hành', description: 'Chạy pha đầu, đo kết quả rồi mở rộng'},
    ],
  },
};

export type LandingCopy = typeof vi;

const en: LandingCopy = {
  meta: {
    title: 'Enterprise data platform with Ontology and AI agents',
    description:
      'Hanas Data Platform queries data where it lives, models your business in an Ontology and lets the Kapas AI agent answer questions inside your own infrastructure.',
    keywords:
      'enterprise data platform, AI agent, Ontology, conversational analytics, lakehouse, Apache Iceberg, data catalog, on-premise data platform',
    schemaDescription:
      'Enterprise data platform: query in place, Apache Iceberg lakehouse, dbt Studio, Hanas Catalog, Ontology and the Kapas AI agent, deployed on-premise or in a private cloud.',
  },
  hero: {
    title: 'One platform.',
    titleAccent: 'Every data journey.',
    subtitle:
      'From connecting sources to building pipelines, analytics and governance, everything lives in one unified workspace. Your team spends its time creating value instead of stitching tools together.',
    primary: 'Book a demo',
    secondary: 'Read the docs',
    board: {
      aria: 'Hanas Data Platform architecture: data sources flow into a query engine and Iceberg lakehouse core, through processing, governance and Ontology layers, out to the Kapas AI agent, BI, applications and business users',
      sourcesTitle: 'Sources',
      sources: [
        {name: 'Databases', meta: 'JDBC', items: 'Oracle, SQL Server, PostgreSQL, MySQL'},
        {name: 'Existing warehouses', meta: 'Query in place', items: 'Snowflake and your current lakehouse'},
        {name: 'Object storage', meta: 'S3', items: 'CSV, JSON and Parquet'},
        {name: 'Business applications', meta: 'REST API', items: 'Core banking, CRM, ERP'},
      ],
      platform: 'Hanas Data Platform',
      platformMeta: 'Kubernetes',
      governTitle: 'Identity & governance',
      govern: [
        {name: 'Keycloak SSO', detail: 'Groups, roles, token exchange'},
        {name: 'Hanas Catalog', detail: 'Owners, glossary, tags, lineage'},
        {name: 'Per-user permissions', detail: 'Checked on every query'},
      ],
      processTitle: 'Processing',
      process: [
        {name: 'Ingestion', detail: 'Scheduled loads with checkpoints'},
        {name: 'dbt Studio', detail: 'Models and tests in the browser'},
        {name: 'Pipeline', detail: 'Scheduled orchestration'},
        {name: 'Compute', detail: 'PySpark and notebooks'},
      ],
      coreTitle: 'Query engine',
      coreMeta: 'One query point for every source',
      lakeTitle: 'Apache Iceberg lakehouse',
      zones: [
        {name: 'Bronze', detail: 'raw'},
        {name: 'Silver', detail: 'cleaned'},
        {name: 'Gold', detail: 'business marts'},
      ],
      features: ['Time travel', 'Schema evolution', 'Snapshots'],
      storage: 'Object storage',
      semanticTitle: 'Semantics for AI agents',
      ontology: {name: 'Ontology', detail: 'Versioned object types, links and metrics'},
      ontologyItems: ['Customer', 'Account', 'Transaction'],
      consumersTitle: 'Consumers',
      consumers: [
        {name: 'Kapas AI agent', meta: 'Ontology + asker\'s permissions', items: 'Ask in plain language, get answers with sources'},
        {name: 'Analytics & BI', meta: 'JDBC · ODBC', items: 'Superset, Power BI, Tableau'},
        {name: 'Apps & code', meta: 'REST · Arrow Flight', items: 'Internal APIs, PySpark, notebooks'},
        {name: 'Business users', meta: 'Hanas Console', items: 'SQL Editor, dashboards, Ontology explorer'},
      ],
    },
    pause: 'Pause animation',
    play: 'Play animation',
  },
  journey: {
    ariaLabel: 'Data journey on Hanas',
    eyebrow: 'How data moves through Hanas',
    scrollCue: 'Scroll to move the data forward',
    visualLabel: 'HANAS / DATA FLOW',
    step: 'Step',
    of: 'of',
    labels: ['Today', 'Connect', 'Ontology', 'AI Agent', 'Use'],
    chapters: [
      {
        title: 'Scattered data, slow reports',
        description: 'Every system holds a piece of your data, so every team reports a different number.',
        outcome: 'Siloed reports · Manual reconciliation',
      },
      {
        title: 'Read data where it lives',
        description: 'Query Oracle, SQL Server, PostgreSQL and object storage directly. Load into Iceberg only when you need a copy.',
        outcome: 'Query engine · Apache Iceberg · dbt',
      },
      {
        title: 'Turn tables into business concepts',
        description: 'Define customers, accounts, transactions and metrics once, then bind them to your real data.',
        outcome: 'Object types · Links · Metrics',
      },
      {
        title: 'Ask a question, get an\u00a0answer you can trace',
        description: 'Kapas reads your Ontology to understand the question, then queries with your permissions. You don\'t need to write SQL.',
        outcome: 'Kapas · Ontology · Your permissions',
      },
      {
        title: 'One number for the whole company',
        description: 'Kapas, dashboards and internal apps all read the metric definitions in the Ontology.',
        outcome: 'Kapas · Superset · API',
      },
    ],
  },
  sources: {
    domains: ['Accounts & transactions', 'Loan applications', 'Customers & segments', 'App events'],
    receiving: 'Receiving data',
  },
  gateway: {
    name: 'Query engine',
    mode: 'Reads in place',
    status: 'Live',
    footer: '3 records converging',
  },
  sample: {
    label: 'Sample data',
    rows: [
      [
        {id: 'GD-2048', value: 'CoreBank · Oracle · 12,800,000'},
        {id: 'KH-01842', value: 'CRM · PostgreSQL · Hanoi'},
        {id: 'EVT-0905', value: 'MobileBanking · object storage'},
      ],
      [
        {id: 'GD-2048', value: 'CoreBank → query engine'},
        {id: 'KH-01842', value: 'CRM → query engine'},
        {id: 'EVT-0905', value: 'MobileBanking → Iceberg'},
      ],
    ],
    ontologyAria: 'Ontology example: objects, links and metrics',
    agentAria: 'Example of Kapas answering a question',
  },
  ontology: {
    subtitle: 'Retail banking · sample data',
    badge: 'v3 · Published',
    objects: [
      {name: 'Customer', properties: ['customer_id', 'segment']},
      {name: 'Account', properties: ['account_no', 'type']},
      {name: 'Branch', properties: ['branch_id', 'region']},
      {name: 'Transaction', properties: ['amount', 'channel']},
    ],
    links: ['owns', 'generates', 'made at', 'opened at'],
    metrics: ['Net revenue', 'Active customers'],
    bound: 'Bound to dataset',
  },
  agent: {
    subtitle: 'Analytics agent · sample data',
    badge: 'Your permissions',
    question: 'How did net revenue in the North this month compare with last month?',
    steps: [
      {label: 'Read the question through the Ontology', detail: 'Transaction → Branch.region'},
      {label: 'Fetch the metric definition', detail: 'metric: Net revenue · v3'},
      {label: 'Run the query in the query engine', detail: 'as you'},
    ],
    answer: {
      before: 'Net revenue in the North reached ',
      value: 'VND 41.2B',
      middle: ' this month, up ',
      change: '6.4%',
      after: ' from last month. The Hanoi branch contributed the most.',
    },
    source: 'Based on the Net revenue metric · Ontology v3',
  },
  dashboard: {
    title: 'Executive overview',
    scope: 'Today · Company-wide',
    synced: 'Synced',
    kpis: [
      {label: 'Net revenue', value: 'VND 128.4B', delta: '↗ 18.6% vs last period'},
      {label: 'Transactions', value: '2.48M', delta: '↗ 7.2% vs last period'},
      {label: 'Active customers', value: '184,920', delta: '↗ 4.8% vs last period'},
    ],
    trendKicker: 'Revenue',
    trendTitle: 'Monthly trend',
    trendDelta: '+24.8%',
    months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    volumeKicker: 'Transactions',
    volumeTitle: 'Transactions by channel',
    volumePill: '12 months',
    valid: 'Valid',
    validValue: '99.97%',
    exceptions: 'Exceptions',
    exceptionsValue: '0.03%',
    footer: ['Period: this month', '4 sources', 'Updated: 10:45'],
    details: 'View details →',
  },
  grid: {
    titleLines: ['Each team gets its own tools', 'under one set of permissions'],
    learnMore: 'Learn about',
    cards: [
      {title: 'Ontology & Kapas AI', description: 'Define your business once in the Ontology, then ask Kapas in plain language.'},
      {title: 'Connect & load', description: 'Query sources directly, and load them into Iceberg on a schedule when you need to keep a copy.'},
      {title: 'Open lakehouse', description: 'Store tables in Apache Iceberg on your own storage, so you can switch engines without moving data.'},
      {title: 'Transform & orchestrate', description: 'Build and test dbt models in the browser, then schedule them with Pipeline.'},
      {title: 'Governance & security', description: 'Sign in once. Every query is checked against the user\'s own permissions, down to the table.'},
      {title: 'Query & BI', description: 'Write SQL, build Superset dashboards or connect Power BI and Tableau over JDBC/ODBC.'},
    ],
  },
  tabs: {
    titleLines: ['Start with one piece', 'and add the rest later'],
    intro: 'Whatever you add next reuses the data, permissions and definitions you already have.',
    listAria: 'Ways to start with Hanas',
    flowTitle: 'How it works',
    items: [
      {
        label: 'Ontology & AI',
        eyebrow: 'For managers and business teams',
        title: 'Ask for the numbers yourself, in plain language',
        description: 'Define "revenue" or "active customer" once in the Ontology. Kapas uses that exact formula, so its answers match your reports and you don\'t wait for someone to write SQL.',
        bullets: ['Kapas queries with the asker\'s own permissions', 'Versioned definitions that apply once published', 'Models via API or self-hosted in your network'],
        flow: ['Tables', 'Ontology definitions', 'Answers from Kapas'],
      },
      {
        label: 'Data foundation',
        eyebrow: 'For data teams',
        title: 'Query the systems you already run',
        description: 'Connect Oracle, SQL Server or PostgreSQL and start querying before you move anything. Load a table into Iceberg later if you need its history or use it often.',
        bullets: ['Join tables across systems in one SQL query', 'Failed loads resume from the last checkpoint', 'Write and test dbt models in the browser'],
        flow: ['Systems you run', 'Query engine', 'Iceberg tables when needed'],
      },
      {
        label: 'Governance & trust',
        eyebrow: 'For IT and security',
        title: 'Everyone sees only the data they\'re cleared for',
        description: 'Branch staff see their own branch\'s customers, and phone numbers stay masked for anyone without access. The same rules apply in SQL Editor, dashboards and Kapas.',
        bullets: ['One Keycloak account for every app', 'Row filters and column masks by policy', 'Catalog shows who owns a table and where it comes from'],
        flow: ['Sign in once', 'Permission check on every query', 'Data within scope'],
      },
    ],
  },
  useCases: {
    titleLines: ['From quick questions', 'to daily pipelines'],
    railAria: 'Typical business problems',
    more: 'Read the docs',
    items: [
      {category: 'Data & analytics', title: 'Conversational analytics', description: 'Ask Kapas the way you would ask a colleague. Answers use the metrics your team already defined.'},
      {category: 'Financial services', title: 'Customer 360', description: 'Combine customers, accounts and transactions into one profile in the Ontology.'},
      {category: 'Self-service BI', title: 'Self-service SQL and dashboards', description: 'Query, save views and build dashboards without filing an IT ticket.'},
      {category: 'Data operations', title: 'Traceable pipelines', description: 'Schedule SQL and dbt steps. When one fails, you see which one right away.'},
    ],
  },
  faq: {
    titleLines: ['Common questions', 'about Hanas'],
    link: 'Read the platform introduction',
    items: [
      {
        question: 'Can Hanas run on-premise?',
        answer: 'Yes. Hanas runs on Kubernetes in your data center or private cloud. Data stays inside your network.',
      },
      {
        question: 'Can we trust the answers from Kapas?',
        answer: 'Kapas calculates from metrics defined in the Ontology, so it uses the same formulas as your reports. Check important results against the source.',
      },
      {
        question: 'Can we use self-hosted AI models?',
        answer: 'Yes. Kapas works with models over API or self-hosted ones such as vLLM and Ollama. Data queries always use the asker\'s token.',
      },
      {
        question: 'Does it connect to our existing systems?',
        answer: 'Yes. Hanas reads Oracle, SQL Server, PostgreSQL, MySQL, Snowflake and object storage. Other applications get data over JDBC, ODBC, Arrow Flight or REST.',
      },
      {
        question: 'How are permissions enforced?',
        answer: 'Users sign in once through Keycloak. Every query runs under the sender\'s identity and is checked in the query engine.',
      },
      {
        question: 'Are we locked into one vendor?',
        answer: 'No. Your data stays on your own infrastructure in Apache Iceberg, an open format. dbt, Spark, Superset and Keycloak are all open source.',
      },
      {
        question: 'Where should we start?',
        answer: 'Pick one problem with clear value and roll out in phases. The results of the first phase decide the next step.',
      },
    ],
  },
  cta: {
    titleLines: ['See Hanas run', 'on your own data'],
    body: 'Book a session to pick your first use case and agree on the rollout scope.',
    action: 'Book a demo',
    actionAria: 'Book a demo by email at thunnv@katalyst.vn',
    mailSubject: 'Hanas Data Platform demo request',
    roadmapTitle: 'Rollout path',
    steps: [
      {title: 'Assess', description: 'Review your infrastructure and pick a priority problem'},
      {title: 'Design', description: 'Agree on the architecture and the scope of each phase'},
      {title: 'Operate', description: 'Run the first phase, measure, then expand'},
    ],
  },
};

const copies: Record<string, LandingCopy> = {vi, en};

export default function useLandingCopy(): LandingCopy {
  const {i18n} = useDocusaurusContext();
  return copies[i18n.currentLocale] ?? vi;
}
