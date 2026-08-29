import React from 'react';
import useLazyVideo from '@site/src/hooks/useLazyVideo';
import styles from './styles.module.css';

interface UseCase {
  category: string;
  title: string;
  description: string;
  signal: string;
  image: string;
  video: string;
  link: string;
}

const useCases: UseCase[] = [
  {
    category: 'Financial Services',
    title: 'Customer 360 & Real-time Risk',
    description: 'Nhìn được toàn cảnh một khách hàng ngay khi giao dịch vừa phát sinh, không phải chờ báo cáo ngày.',
    signal: 'STREAM / PROFILE / DECIDE',
    image: '/img/landing/use-case-financial.webp',
    video: '/video/dashboard-with-manager.mp4',
    link: '/federation',
  },
  {
    category: 'Data & Analytics',
    title: 'Conversational Analytics',
    description: 'Người dùng nghiệp vụ hỏi bằng ngôn ngữ thường ngày, trên lớp dữ liệu đã được định nghĩa sẵn ý nghĩa.',
    signal: 'ASK / QUERY / EXPLAIN',
    image: '/img/landing/use-case-analytics.webp',
    video: '/video/dashboard-simple.mp4',
    link: '/visualization',
  },
  {
    category: 'Enterprise AI',
    title: 'Knowledge Assistant',
    description: 'Nhân viên hỏi một câu, nhận câu trả lời rút từ tài liệu và dữ liệu nội bộ của chính doanh nghiệp.',
    signal: 'RETRIEVE / REASON / RESPOND',
    image: '/img/landing/use-case-ai.webp',
    video: '/video/agentic-ai.mp4',
    link: '/ai-service',
  },
  {
    category: 'Data Operations',
    title: 'Intelligent Data Operations',
    description: 'Biết pipeline hỏng ở đâu trước khi người dùng phàn nàn, kèm đủ ngữ cảnh để xử lý ngay.',
    signal: 'OBSERVE / DETECT / ACT',
    image: '/img/landing/use-case-operations.webp',
    video: '/video/modern-dashboard-monitoring.mp4',
    link: '/system-management',
  },
];

function UseCaseCard({category, title, description, signal, image, video, link}: UseCase): React.JSX.Element {
  const videoRef = useLazyVideo();
  return (
    <article className={styles.card}>
      <div className={styles.visual} aria-hidden="true">
        <img src={image} alt="" loading="lazy" decoding="async" />
        <video
          ref={videoRef}
          muted
          loop
          playsInline
          preload="none"
          poster={image}
          aria-hidden="true"
        >
          <source src={video} type="video/mp4" />
        </video>
        <div className={styles.visualTop}>
          <span className={styles.visualSignal}>{signal}</span>
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
            <h2>
              Thiết kế cho workflow
              <br className="landingDesktopBreak" />{' '}
              tạo ra giá trị thật
            </h2>
          </div>
          <p>
            Cùng một nền tảng, nhiều bài toán khác nhau. Dù là báo cáo hay ứng dụng AI,
            cách quản trị và bảo mật vẫn là một.
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
