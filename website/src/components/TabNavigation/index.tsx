import React, {useState} from 'react';
import useLazyVideo, {posterOf} from '@site/src/hooks/useLazyVideo';
import styles from './styles.module.css';

type TabId = 'foundation' | 'intelligence' | 'governance';

interface Experience {
  id: TabId;
  label: string;
  eyebrow: string;
  title: string;
  description: string;
  bullets: string[];
  flow: string[];
  video: string;
}

const experiences: Experience[] = [
  {
    id: 'foundation',
    label: 'Nền tảng dữ liệu',
    eyebrow: 'Nền tảng dữ liệu hiện đại',
    title: 'Tạo một nguồn dữ liệu tin cậy cho toàn doanh nghiệp',
    description: 'Hợp nhất dữ liệu phân tán vào Lakehouse mở, xử lý đồng thời batch và real-time mà vẫn giữ nguyên khả năng mở rộng theo nhu cầu.',
    bullets: [
      'Ingestion đa nguồn, hỗ trợ CDC và streaming',
      'Table format mở, tách biệt compute và storage',
      'Pipeline được điều phối và quan sát xuyên suốt',
    ],
    flow: ['Data Sources', 'Open Lakehouse', 'Data Products'],
    video: '/video/background-data.mp4',
  },
  {
    id: 'intelligence',
    label: 'AI doanh nghiệp',
    eyebrow: 'AI gắn với dữ liệu doanh nghiệp',
    title: 'Đưa AI từ thử nghiệm vào quy trình vận hành thực tế',
    description: 'Kết nối dữ liệu đã được quản trị với LLM, knowledge base và workflow AI để xây dựng ứng dụng có thể đánh giá, theo dõi và cải tiến liên tục.',
    bullets: [
      'Triển khai LLM self-hosted hoặc kết nối model API',
      'Xây dựng RAG, agent và workflow trực quan',
      'Theo dõi prompt, chất lượng và chi phí inference',
    ],
    flow: ['Governed Data', 'LLM Mesh', 'AI Applications'],
    video: '/video/main-background-landing-page.mp4',
  },
  {
    id: 'governance',
    label: 'Quản trị & Tin cậy',
    eyebrow: 'Kiểm soát theo thiết kế',
    title: 'Đưa quản trị dữ liệu vào ngay trong kiến trúc',
    description: 'Metadata, lineage, chất lượng dữ liệu, phân quyền và secret management vận hành xuyên suốt thay vì được bổ sung rời rạc về sau.',
    bullets: [
      'Data catalog và lineage xuyên suốt hệ thống',
      'Chính sách truy cập nhất quán theo vai trò',
      'Audit, observability và bảo mật tập trung',
    ],
    flow: ['Metadata', 'Policy Engine', 'Trusted Access'],
    video: '/video/digital-dashboard.mp4',
  },
];

export default function TabNavigation(): React.JSX.Element {
  const [activeTab, setActiveTab] = useState<TabId>('foundation');
  const activeExperience = experiences.find((experience) => experience.id === activeTab) ?? experiences[0];
  const videoRef = useLazyVideo([activeExperience.video]);

  const moveTab = (direction: number) => {
    const currentIndex = experiences.findIndex((experience) => experience.id === activeTab);
    const nextIndex = (currentIndex + direction + experiences.length) % experiences.length;
    setActiveTab(experiences[nextIndex].id);
  };

  return (
    <section className={styles.section}>
      <div className="container">
        <div className={styles.header}>
          <span className={styles.eyebrow}>Từ dữ liệu đến giá trị</span>
          <h2>
            Ba điểm bắt đầu
            <br className="landingDesktopBreak" />{' '}
            Một nền tảng để mở rộng
          </h2>
          <p>
            Doanh nghiệp có thể bắt đầu từ dữ liệu, AI hoặc quản trị — rồi mở rộng
            theo nhu cầu mà không phải xây lại nền tảng.
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
                <strong>{experience.label}</strong>
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
              <div className={styles.panelNarrative}>
                <span className={styles.panelEyebrow}>{activeExperience.eyebrow}</span>
                <h3>{activeExperience.title}</h3>
                <p>{activeExperience.description}</p>
              </div>
              <ul>
                {activeExperience.bullets.map((bullet) => (
                  <li key={bullet}>
                    <span aria-hidden="true">✓</span>
                    {bullet}
                  </li>
                ))}
              </ul>
            </div>

            <div className={styles.flowVisual} aria-label={`Luồng ${activeExperience.flow.join(' đến ')}`}>
              <video
                key={activeExperience.video}
                className={styles.flowVideo}
                ref={videoRef}
                muted
                loop
                playsInline
                preload="none"
                poster={posterOf(activeExperience.video)}
                aria-hidden="true"
              >
                <source src={activeExperience.video} type="video/mp4" />
              </video>
              <div className={styles.flowStages}>
                {activeExperience.flow.map((stage) => (
                  <strong key={stage}>{stage}</strong>
                ))}
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>
  );
}
