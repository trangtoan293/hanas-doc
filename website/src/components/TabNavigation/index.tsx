import React, {useState} from 'react';
import styles from './styles.module.css';

type TabId = 'foundation' | 'intelligence' | 'governance';

interface Experience {
  id: TabId;
  number: string;
  label: string;
  eyebrow: string;
  title: string;
  description: string;
  bullets: string[];
  flow: string[];
}

const experiences: Experience[] = [
  {
    id: 'foundation',
    number: '01',
    label: 'Data Foundation',
    eyebrow: 'Nền tảng dữ liệu hiện đại',
    title: 'Tạo một nguồn dữ liệu tin cậy cho toàn doanh nghiệp.',
    description: 'Hợp nhất dữ liệu phân tán vào Lakehouse mở, xử lý đồng thời batch và real-time mà vẫn giữ nguyên khả năng mở rộng theo nhu cầu.',
    bullets: [
      'Ingestion đa nguồn, hỗ trợ CDC và streaming',
      'Table format mở, tách biệt compute và storage',
      'Pipeline được điều phối và quan sát xuyên suốt',
    ],
    flow: ['Data Sources', 'Open Lakehouse', 'Data Products'],
  },
  {
    id: 'intelligence',
    number: '02',
    label: 'AI & Intelligence',
    eyebrow: 'AI gắn với dữ liệu doanh nghiệp',
    title: 'Đưa AI từ thử nghiệm vào quy trình vận hành thực tế.',
    description: 'Kết nối dữ liệu đã được quản trị với LLM, knowledge base và workflow AI để xây dựng ứng dụng có thể đánh giá, theo dõi và cải tiến liên tục.',
    bullets: [
      'Triển khai LLM self-hosted hoặc kết nối model API',
      'Xây dựng RAG, agent và workflow trực quan',
      'Theo dõi prompt, chất lượng và chi phí inference',
    ],
    flow: ['Governed Data', 'LLM Mesh', 'AI Applications'],
  },
  {
    id: 'governance',
    number: '03',
    label: 'Trust & Governance',
    eyebrow: 'Kiểm soát theo thiết kế',
    title: 'Biến quản trị dữ liệu thành một phần của platform.',
    description: 'Metadata, lineage, quality, access policy và secret management được tích hợp ngay trong kiến trúc thay vì xử lý rời rạc sau khi hệ thống đã vận hành.',
    bullets: [
      'Data catalog và lineage xuyên suốt hệ thống',
      'Chính sách truy cập nhất quán theo vai trò',
      'Audit, observability và bảo mật tập trung',
    ],
    flow: ['Metadata', 'Policy Engine', 'Trusted Access'],
  },
];

export default function TabNavigation(): React.JSX.Element {
  const [activeTab, setActiveTab] = useState<TabId>('foundation');
  const activeExperience = experiences.find((experience) => experience.id === activeTab) ?? experiences[0];

  const moveTab = (direction: number) => {
    const currentIndex = experiences.findIndex((experience) => experience.id === activeTab);
    const nextIndex = (currentIndex + direction + experiences.length) % experiences.length;
    setActiveTab(experiences[nextIndex].id);
  };

  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <span className={styles.eyebrow}>Từ data đến intelligence</span>
          <h2>Một kiến trúc, nhiều hành trình chuyển đổi.</h2>
          <p>
            Bắt đầu từ nền tảng dữ liệu, năng lực AI hay bài toán quản trị — Hanas cho phép
            doanh nghiệp mở rộng theo từng giai đoạn mà không phải xây lại từ đầu.
          </p>
        </div>

        <div className={styles.experienceShell}>
          <div className={styles.tabList} role="tablist" aria-label="Các hành trình với Hanas Platform">
            {experiences.map((experience) => (
              <button
                key={experience.id}
                id={`tab-${experience.id}`}
                type="button"
                role="tab"
                aria-selected={activeTab === experience.id}
                aria-controls={`panel-${experience.id}`}
                tabIndex={activeTab === experience.id ? 0 : -1}
                className={`${styles.tabButton} ${activeTab === experience.id ? styles.tabButtonActive : ''}`}
                onClick={() => setActiveTab(experience.id)}
                onKeyDown={(event) => {
                  if (event.key === 'ArrowDown' || event.key === 'ArrowRight') {
                    event.preventDefault();
                    moveTab(1);
                  }
                  if (event.key === 'ArrowUp' || event.key === 'ArrowLeft') {
                    event.preventDefault();
                    moveTab(-1);
                  }
                }}
              >
                <span>{experience.number}</span>
                <strong>{experience.label}</strong>
                <i aria-hidden="true">→</i>
              </button>
            ))}
          </div>

          <article
            id={`panel-${activeExperience.id}`}
            role="tabpanel"
            aria-labelledby={`tab-${activeExperience.id}`}
            className={styles.panel}
          >
            <div className={styles.panelContent}>
              <span className={styles.panelEyebrow}>{activeExperience.eyebrow}</span>
              <h3>{activeExperience.title}</h3>
              <p>{activeExperience.description}</p>
              <ul>
                {activeExperience.bullets.map((bullet) => (
                  <li key={bullet}>
                    <span aria-hidden="true">✓</span>
                    {bullet}
                  </li>
                ))}
              </ul>
              <a href="/overview/architecture">
                Xem thiết kế kiến trúc <span aria-hidden="true">↗</span>
              </a>
            </div>

            <div className={styles.flowVisual} aria-label={`Luồng ${activeExperience.flow.join(' đến ')}`}>
              <div className={styles.flowTopline}>
                <span>REFERENCE FLOW / {activeExperience.number}</span>
                <span className={styles.flowStatus}><i aria-hidden="true" /> Connected</span>
              </div>
              <div className={styles.flowStages}>
                {activeExperience.flow.map((stage, index) => (
                  <React.Fragment key={stage}>
                    <div className={`${styles.flowStage} ${index === 1 ? styles.flowStageCore : ''}`}>
                      <span>{String(index + 1).padStart(2, '0')}</span>
                      <strong>{stage}</strong>
                      <small>{index === 1 ? 'Powered by Hanas' : 'Enterprise ready'}</small>
                    </div>
                    {index < activeExperience.flow.length - 1 && (
                      <div className={styles.flowArrow} aria-hidden="true">→</div>
                    )}
                  </React.Fragment>
                ))}
              </div>
              <div className={styles.flowTelemetry}>
                <span>Observability</span>
                <span>Security</span>
                <span>Lineage</span>
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>
  );
}
