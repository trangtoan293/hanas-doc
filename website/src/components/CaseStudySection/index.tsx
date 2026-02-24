import React, { useState } from 'react';
import styles from './styles.module.css';

interface CaseStudy {
  id: string;
  companyName: string;
  logo: string;
  title: string;
  description: string;
  stats: { value: string; label: string }[];
  imageAlt: string;
}

const caseStudies: CaseStudy[] = [
  {
    id: 'company-a',
    companyName: 'TechCorp',
    logo: '🔷',
    title: 'Tăng 50% hiệu suất xử lý dữ liệu',
    description:
      'Bằng cách tối ưu hóa quy trình ETL và áp dụng kiến trúc Data Lakehouse, công ty đã đạt được hiệu suất xử lý dữ liệu vượt trội, giảm thờigian báo cáo từ vài giờ xuống chỉ còn vài phút.',
    stats: [
      { value: '50%', label: 'faster processing' },
      { value: '10TB', label: 'daily data volume' },
    ],
    imageAlt: 'TechCorp data dashboard',
  },
  {
    id: 'company-b',
    companyName: 'DataFlow',
    logo: '⚡',
    title: 'Giảm 70% chi phí lưu trữ',
    description:
      'Chuyển đổi từ hệ thống data warehouse truyền thống sang Data Lakehouse đã giúp giảm đáng kể chi phí lưu trữ trong khi vẫn đảm bảo tính sẵn sàng cao và hiệu năng truy vấn tối ưu.',
    stats: [
      { value: '70%', label: 'cost reduction' },
      { value: '99.9%', label: 'uptime guaranteed' },
    ],
    imageAlt: 'DataFlow infrastructure',
  },
];

export default function CaseStudySection(): JSX.Element {
  const [activeTab, setActiveTab] = useState<string>(caseStudies[0].id);
  const activeCaseStudy = caseStudies.find((cs) => cs.id === activeTab) || caseStudies[0];

  return (
    <section className={styles.caseStudySection}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <h2 className={styles.sectionTitle}>Case Studies</h2>
          <p className={styles.sectionSubtitle}>
            Khám phá cách các doanh nghiệp hàng đầu đã chuyển đổi dữ liệu với Hanas
          </p>
        </div>

        <div className={styles.tabsContainer}>
          {caseStudies.map((caseStudy) => (
            <button
              key={caseStudy.id}
              className={`${styles.tabButton} ${
                activeTab === caseStudy.id ? styles.tabButtonActive : ''
              }`}
              onClick={() => setActiveTab(caseStudy.id)}
              aria-pressed={activeTab === caseStudy.id}
            >
              <span className={styles.tabLogo}>{caseStudy.logo}</span>
              <span className={styles.tabLabel}>{caseStudy.companyName}</span>
            </button>
          ))}
        </div>

        <div className={styles.contentWrapper}>
          <div className={styles.contentColumn}>
            <h3 className={styles.caseTitle}>{activeCaseStudy.title}</h3>
            <p className={styles.caseDescription}>{activeCaseStudy.description}</p>

            <div className={styles.statsContainer}>
              {activeCaseStudy.stats.map((stat, index) => (
                <div key={index} className={styles.statItem}>
                  <div className={styles.statValue}>{stat.value}</div>
                  <div className={styles.statLabel}>{stat.label}</div>
                </div>
              ))}
            </div>

            <span className={styles.readStoryLink}>
              Read the story
              <svg
                className={styles.arrowIcon}
                width="20"
                height="20"
                viewBox="0 0 20 20"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  d="M4.167 10h11.666m0 0L10 4.167M15.833 10L10 15.833"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            </span>
          </div>

          <div className={styles.imageColumn}>
            <div className={styles.imagePlaceholder}>
              <span className={styles.imageIcon}>📊</span>
              <span className={styles.imageCaption}>{activeCaseStudy.imageAlt}</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
