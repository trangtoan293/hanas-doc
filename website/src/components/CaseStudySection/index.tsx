import React from 'react';
import styles from './styles.module.css';

export default function CaseStudySection(): React.JSX.Element {
  const stats = [
    {
      value: '50%',
      label: 'Hiệu suất tăng',
      description: 'So với giải pháp truyền thống',
    },
    {
      value: '70%',
      label: 'Chi phí giảm',
      description: 'Với kiến trúc Lakehouse tối ưu',
    },
    {
      value: '99.9%',
      label: 'Uptime',
      description: 'SLA đảm bảo cho enterprise',
    },
  ];

  return (
    <section className={styles.caseStudySection}>
      <div className="container">
        <div className={styles.content}>
          <h2 className={styles.sectionTitle}>Kết Quả Thực Tế</h2>
          <p className={styles.sectionSubtitle}>
            Những con số chứng minh hiệu quả của nền tảng Hanas
          </p>
          <div className={styles.stats}>
            {stats.map((stat, index) => (
              <React.Fragment key={stat.label}>
                <div className={styles.statItem}>
                  <div className={styles.statValue}>{stat.value}</div>
                  <div className={styles.statLabel}>{stat.label}</div>
                  <div className={styles.statDescription}>{stat.description}</div>
                </div>
                {index < stats.length - 1 && <div className={styles.separator} />}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
