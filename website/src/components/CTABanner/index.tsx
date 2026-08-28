import React from 'react';
import styles from './styles.module.css';

const roadmap = [
  {number: '01', title: 'Đánh giá hiện trạng', description: 'Dữ liệu, hạ tầng và bài toán ưu tiên'},
  {number: '02', title: 'Thiết kế blueprint', description: 'Kiến trúc và lộ trình triển khai phù hợp'},
  {number: '03', title: 'Triển khai theo pha', description: 'Tạo giá trị sớm, mở rộng có kiểm soát'},
];

export default function CTABanner(): React.JSX.Element {
  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.shell}>
          <div className={styles.glow} aria-hidden="true" />
          <div className={styles.content}>
            <span className={styles.eyebrow}>Build what matters</span>
            <h2>Sẵn sàng biến dữ liệu thành năng lực cạnh tranh?</h2>
            <p>
              Mỗi doanh nghiệp có hạ tầng và điểm xuất phát khác nhau. Bắt đầu bằng một
              buổi trao đổi để dựng lộ trình sát với tình hình thực tế.
            </p>
            <div className={styles.actions}>
              <a href="/overview" className={styles.primaryAction}>
                Bắt đầu với Hanas <span aria-hidden="true">↗</span>
              </a>
              <a
                href="https://portal.hanas.io/portal/home/dashboard"
                target="_blank"
                rel="noreferrer"
                className={styles.secondaryAction}
              >
                Truy cập Portal <span aria-hidden="true">→</span>
              </a>
            </div>
          </div>

          <div className={styles.roadmap}>
            <div className={styles.roadmapHeader}>
              <span>ENGAGEMENT ROADMAP</span>
              <i aria-hidden="true" />
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
