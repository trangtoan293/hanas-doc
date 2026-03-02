import React, { useState } from 'react';
import styles from './styles.module.css';

type TabId = 'overview' | 'features' | 'usecases' | 'resources';

// SVG Icon Components (20x20)
const GlobeIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <circle cx="12" cy="12" r="10" />
    <line x1="2" y1="12" x2="22" y2="12" />
    <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
  </svg>
);

const LightningIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" />
  </svg>
);

const BriefcaseIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <rect x="2" y="7" width="20" height="14" rx="2" ry="2" />
    <path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16" />
  </svg>
);

const BookIcon = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
    <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
    <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
  </svg>
);

const iconMap: Record<TabId, React.FC> = {
  overview: GlobeIcon,
  features: LightningIcon,
  usecases: BriefcaseIcon,
  resources: BookIcon,
};

interface Tab {
  id: TabId;
  label: string;
  items: string[];
}

const tabs: Tab[] = [
  {
    id: 'overview',
    label: 'Tổng Quan',
    items: [
      'Nền tảng dữ liệu toàn diện giúp doanh nghiệp quản lý, phân tích và khai thác dữ liệu một cách hiệu quả',
      'Kiến trúc cloud-native và khả năng mở rộng linh hoạt',
      'Giải pháp dữ liệu end-to-end cho mọi quy mô doanh nghiệp'
    ]
  },
  {
    id: 'features',
    label: 'Tính Năng',
    items: [
      'Xử lý dữ liệu real-time với độ trễ thấp',
      'Tích hợp AI/ML cho phân tích dự đoán',
      'Bảo mật dữ liệu cấp enterprise với mã hóa end-to-end',
      'Khả năng mở rộng tự động theo nhu cầu',
      'API Gateway để kết nối dễ dàng với hệ thống hiện có'
    ]
  },
  {
    id: 'usecases',
    label: 'Use Cases',
    items: [
      'Phân tích hành vi khách hàng trong thờigian thực',
      'Dự báo xu hướng thị trường và nhu cầu sản phẩm',
      'Tối ưu hóa chuỗi cung ứng thông minh',
      'Phát hiện gian lận và bảo mật nâng cao',
      'Cá nhân hóa trải nghiệm ngườidùng trên quy mô lớn'
    ]
  },
  {
    id: 'resources',
    label: 'Tài Nguyên',
    items: [
      'Documentation đầy đủ với ví dụ code',
      'Video tutorials từ cơ bản đến nâng cao',
      'REST API Reference với Swagger UI',
      'SDK cho Python, JavaScript, Java và Go',
      'Community Forum để trao đổi và học hỏi',
      '24/7 Technical Support cho khách hàng doanh nghiệp'
    ]
  }
];

export default function TabNavigation(): React.JSX.Element {
  const [activeTab, setActiveTab] = useState<TabId>('overview');

  const handleTabClick = (tabId: TabId) => {
    setActiveTab(tabId);
  };

  const activeTabData = tabs.find(tab => tab.id === activeTab);

  return (
    <section className={styles.tabSection}>
      <div className={styles.tabContainer}>
        <div 
          className={styles.tabList}
          role="tablist"
          aria-label="Platform navigation tabs"
        >
          {tabs.map((tab) => {
            const IconComponent = iconMap[tab.id];
            return (
              <button
                key={tab.id}
                id={`tab-${tab.id}`}
                role="tab"
                aria-selected={activeTab === tab.id}
                aria-controls={`panel-${tab.id}`}
                tabIndex={activeTab === tab.id ? 0 : -1}
                className={`${styles.tabButton} ${activeTab === tab.id ? styles.tabButtonActive : ''}`}
                onClick={() => handleTabClick(tab.id)}
                onKeyDown={(e) => {
                  if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
                    e.preventDefault();
                    const currentIndex = tabs.findIndex(t => t.id === activeTab);
                    const direction = e.key === 'ArrowRight' ? 1 : -1;
                    const newIndex = (currentIndex + direction + tabs.length) % tabs.length;
                    setActiveTab(tabs[newIndex].id);
                  }
                }}
              >
                <span className={styles.tabIcon}>
                  <IconComponent />
                </span>
                <span className={styles.tabLabel}>{tab.label}</span>
              </button>
            );
          })}
        </div>
        
        <div className={styles.tabPanels}>
          {tabs.map((tab) => (
            <div
              key={tab.id}
              id={`panel-${tab.id}`}
              role="tabpanel"
              aria-labelledby={`tab-${tab.id}`}
              className={`${styles.tabPanel} ${activeTab === tab.id ? styles.tabPanelActive : ''}`}
              hidden={activeTab !== tab.id}
            >
              <ul className={styles.tabContentList}>
                {tab.items.map((item, index) => (
                  <li key={index} className={styles.tabContentItem}>{item}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
