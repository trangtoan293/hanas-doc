import React from 'react';
import styles from './styles.module.css';

type CardTone = 'navy' | 'surface' | 'mist';

interface UseCase {
  category: string;
  title: string;
  description: string;
  signal: string;
  link: string;
  tone: CardTone;
}

const useCases: UseCase[] = [
  {
    category: 'Financial Services',
    title: 'Customer 360 & Real-time Risk',
    description: 'Hợp nhất giao dịch và hành vi khách hàng để hỗ trợ phân tích tức thời trên dữ liệu được quản trị.',
    signal: 'STREAM / PROFILE / DECIDE',
    link: '/federation',
    tone: 'navy',
  },
  {
    category: 'Data & Analytics',
    title: 'Conversational Analytics',
    description: 'Cho phép người dùng nghiệp vụ đặt câu hỏi bằng ngôn ngữ tự nhiên trên semantic layer đáng tin cậy.',
    signal: 'ASK / QUERY / EXPLAIN',
    link: '/visualization',
    tone: 'surface',
  },
  {
    category: 'Enterprise AI',
    title: 'Knowledge Assistant',
    description: 'Xây dựng trợ lý tri thức kết nối tài liệu nội bộ, dữ liệu vận hành và các mô hình AI riêng tư.',
    signal: 'RETRIEVE / REASON / RESPOND',
    link: '/ai-service',
    tone: 'mist',
  },
  {
    category: 'Data Operations',
    title: 'Intelligent Data Operations',
    description: 'Quan sát pipeline, phát hiện bất thường và hỗ trợ đội ngũ vận hành xử lý sự cố có đầy đủ ngữ cảnh.',
    signal: 'OBSERVE / DETECT / ACT',
    link: '/system-management',
    tone: 'surface',
  },
];

function UseCaseCard({category, title, description, signal, link, tone}: UseCase): React.JSX.Element {
  return (
    <article className={`${styles.card} ${styles[tone]}`}>
      <div className={styles.visual} aria-hidden="true">
        <span className={styles.visualSignal}>{signal}</span>
        <div className={styles.visualPath}>
          <i />
          <i />
          <i />
        </div>
        <div className={styles.visualCore}>H</div>
        <div className={styles.visualMetric}>
          <span>Enterprise context</span>
          <strong>Connected</strong>
        </div>
      </div>
      <div className={styles.cardContent}>
        <span className={styles.category}>{category}</span>
        <h3>{title}</h3>
        <p>{description}</p>
        <a href={link}>
          Khám phá giải pháp <span aria-hidden="true">↗</span>
        </a>
      </div>
    </article>
  );
}

export default function UseCasesSection(): React.JSX.Element {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <div>
            <span className={styles.eyebrow}>Enterprise use cases</span>
            <h2>Được thiết kế cho những workflow tạo ra giá trị thật.</h2>
          </div>
          <p>
            Một nền tảng dùng chung cho nhiều bài toán — từ phân tích dữ liệu đến ứng dụng AI —
            với governance, security và observability nhất quán.
          </p>
        </div>

        <div className={styles.rail} aria-label="Các bài toán doanh nghiệp tiêu biểu">
          {useCases.map((useCase) => (
            <UseCaseCard key={useCase.title} {...useCase} />
          ))}
        </div>
      </div>
    </section>
  );
}
