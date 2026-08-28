import React from 'react';
import styles from './styles.module.css';

const roadmap = [
  {
    number: '01',
    title: 'Khảo sát hiện trạng',
    description: 'Làm rõ hạ tầng, dữ liệu và bài toán ưu tiên',
  },
  {
    number: '02',
    title: 'Thiết kế lộ trình',
    description: 'Chốt kiến trúc và phạm vi triển khai theo pha',
  },
  {
    number: '03',
    title: 'Đưa vào vận hành',
    description: 'Tạo giá trị sớm, đo lường rồi mở rộng',
  },
];

export default function CTABanner(): React.JSX.Element {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.shell}>
          <video
            className={styles.backgroundVideo}
            autoPlay
            muted
            loop
            playsInline
            preload="metadata"
            poster="/img/landing/use-case-operations.webp"
            aria-hidden="true"
          >
            <source src="/video/coding-vertical.mp4" type="video/mp4" media="(max-width: 600px)" />
            <source src="/video/coding-monitor.mp4" type="video/mp4" />
          </video>
          <div className={styles.glow} aria-hidden="true" />
          <div className={styles.content}>
            <span className={styles.eyebrow}>Build what matters</span>
            <h2>
              Sẵn sàng biến dữ liệu
              <br className="landingDesktopBreak" />{' '}
              thành năng lực cạnh tranh?
            </h2>
            <p>
              Mỗi doanh nghiệp có hạ tầng và điểm xuất phát khác nhau. Bắt đầu bằng một
              buổi trao đổi để dựng lộ trình sát với tình hình thực tế.
            </p>
            <div className={styles.actions}>
              <a
                href="mailto:thunnv@katalyst.vn"
                className={styles.primaryAction}
                aria-label="Contact us qua email thunnv@katalyst.vn"
              >
                Contact us <span aria-hidden="true">→</span>
              </a>
            </div>
          </div>

          <div className={styles.roadmap}>
            <div className={styles.roadmapHeader}>
              <span>Lộ trình đồng hành</span>
            </div>
            {roadmap.map((step) => (
              <div key={step.number} className={styles.roadmapStep}>
                <span>{step.number}</span>
                <div>
                  <strong>{step.title}</strong>
                  <small>{step.description}</small>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
