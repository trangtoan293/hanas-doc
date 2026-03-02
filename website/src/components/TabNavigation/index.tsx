import React, { useState } from 'react';
import styles from './styles.module.css';

type TabId = 'overview' | 'features' | 'usecases' | 'resources';

interface Tab {
  id: TabId;
  label: string;
  content: string;
}

const tabs: Tab[] = [
  {
    id: 'overview',
    label: 'Tổng Quan',
    content: 'Tổng quan về Hanas Data Platform - Nền tảng dữ liệu toàn diện giúp doanh nghiệp quản lý, phân tích và khai thác dữ liệu một cách hiệu quả. Với kiến trúc cloud-native và khả năng mở rộng linh hoạt, Hanas mang đến giải pháp dữ liệu end-to-end cho mọi quy mô doanh nghiệp.'
  },
  {
    id: 'features',
    label: 'Tính Năng',
    content: 'Các tính năng chính của nền tảng bao gồm: Xử lý dữ liệu real-time với độ trễ thấp, Tích hợp AI/ML cho phân tích dự đoán, Bảo mật dữ liệu cấp enterprise với mã hóa end-to-end, Khả năng mở rộng tự động theo nhu cầu, và API Gateway để kết nối dễ dàng với hệ thống hiện có.'
  },
  {
    id: 'usecases',
    label: 'Use Cases',
    content: 'Các trường hợp sử dụng phổ biến: Phân tích hành vi khách hàng trong thờigian thực, Dự báo xu hướng thị trường và nhu cầu sản phẩm, Tối ưu hóa chuỗi cung ứng thông minh, Phát hiện gian lận và bảo mật nâng cao, Cá nhân hóa trải nghiệm ngườidùng trên quy mô lớn.'
  },
  {
    id: 'resources',
    label: 'Tài Nguyên',
    content: 'Tài liệu và hướng dẫn: Documentation đầy đủ với ví dụ code, Video tutorials từ cơ bản đến nâng cao, REST API Reference với Swagger UI, SDK cho Python, JavaScript, Java và Go, Community Forum để trao đổi và học hỏi, và 24/7 Technical Support cho khách hàng doanh nghiệp.'
  }
];

export default function TabNavigation(): React.JSX.Element {
  const [activeTab, setActiveTab] = useState<TabId>('overview');

  const handleTabClick = (tabId: TabId) => {
    setActiveTab(tabId);
  };

  const activeTabData = tabs.find(tab => tab.id === activeTab);

  return (
    <div className={styles.tabContainer}>
      <div 
        className={styles.tabList}
        role="tablist"
        aria-label="Platform navigation tabs"
      >
        {tabs.map((tab) => (
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
            {tab.label}
          </button>
        ))}
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
            <p className={styles.tabContent}>{tab.content}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
