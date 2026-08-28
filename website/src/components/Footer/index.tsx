import React from 'react';
import styles from './styles.module.css';

const footerColumns = [
  {
    title: 'Product',
    links: [
      { label: 'Tổng Quan', href: '/overview' },
      { label: 'Kiến Trúc', href: '/overview/architecture' },
      { label: 'Quickstart', href: '/guides/quickstart' },
    ],
  },
  {
    title: 'Resources',
    links: [
      { label: 'Tài Liệu', href: '/' },
      { label: 'Thu Thập', href: '/ingestion' },
      { label: 'Lưu Trữ', href: '/storage' },
    ],
  },
  {
    title: 'Company',
    links: [
      { label: 'Giới Thiệu', href: '/overview' },
      { label: 'Hướng dẫn hỗ trợ', href: '/guides/troubleshooting' },
    ],
  },
  {
    title: 'Learn',
    links: [
      { label: 'Quản trị dữ liệu', href: '/governance' },
      { label: 'Xử Lý', href: '/processing' },
      { label: 'Hướng Dẫn', href: '/guides' },
    ],
  },
];

export default function Footer(): React.ReactElement {
  const currentYear = new Date().getFullYear();

  return (
    <footer className={styles.footer}>
      <div className={styles.container}>
        <div className={styles.content}>
          <div className={styles.columns}>
            {footerColumns.map((column) => (
              <div key={column.title} className={styles.column}>
                <h3 className={styles.columnTitle}>{column.title}</h3>
                <ul className={styles.linkList}>
                  {column.links.map((link) => (
                    <li key={link.label}>
                      <a href={link.href} className={styles.link}>
                        {link.label}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>

        <div className={styles.bottom}>
          <p className={styles.copyright}>
            © {currentYear} HANAS. All rights reserved.
          </p>
        </div>
      </div>
    </footer>
  );
}
