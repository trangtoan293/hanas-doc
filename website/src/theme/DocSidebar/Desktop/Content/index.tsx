import React, { type ReactNode, useCallback, useState, useEffect, useRef } from 'react';
import Content from '@theme-original/DocSidebar/Desktop/Content';
import type ContentType from '@theme/DocSidebar/Desktop/Content';
import type { WrapperProps } from '@docusaurus/types';

type Props = WrapperProps<typeof ContentType>;

function ExpandCollapseButton(): ReactNode {
  const [allExpanded, setAllExpanded] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);

  // Sync state by checking actual DOM — in case user manually expands/collapses
  const syncState = useCallback(() => {
    const collapsed = document.querySelectorAll(
      '.menu__list-item--collapsed'
    );
    setAllExpanded(collapsed.length === 0);
  }, []);

  useEffect(() => {
    // Observe sidebar mutations to keep button state in sync
    const sidebar = document.querySelector('.menu');
    if (!sidebar) return;
    const observer = new MutationObserver(syncState);
    observer.observe(sidebar, { subtree: true, attributeFilter: ['class'] });
    return () => observer.disconnect();
  }, [syncState]);

  const handleClick = useCallback(() => {
    // All category toggle buttons that control expand/collapse
    const toggleButtons = document.querySelectorAll<HTMLElement>(
      '.menu__link--sublist'
    );

    if (!allExpanded) {
      // Expand all: click every collapsed item
      document.querySelectorAll<HTMLElement>(
        '.menu__list-item--collapsed .menu__link--sublist'
      ).forEach((btn) => btn.click());
      setAllExpanded(true);
    } else {
      // Collapse all: click every expanded item
      toggleButtons.forEach((btn) => {
        const li = btn.closest('.menu__list-item');
        if (li && !li.classList.contains('menu__list-item--collapsed')) {
          btn.click();
        }
      });
      setAllExpanded(false);
    }
  }, [allExpanded]);

  return (
    <div className="sidebar-expand-collapse-btn-wrap">
      <button
        ref={buttonRef}
        type="button"
        className="sidebar-expand-collapse-btn"
        onClick={handleClick}
        title={allExpanded ? 'Collapse' : 'Expand'}
      >
        <span className="sidebar-expand-collapse-btn__icon">
          {allExpanded ? (
            // Collapse all icon (fold inward)
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M4 2L8 5L12 2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M4 14L8 11L12 14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M2 8H14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          ) : (
            // Expand all icon (unfold outward)
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M4 6L8 3L12 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M4 10L8 13L12 10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M2 8H14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>
          )}
        </span>
        <span className="sidebar-expand-collapse-btn__label">
          {allExpanded ? 'Thu gọn' : 'Mở rộng'}
        </span>
      </button>
    </div>
  );
}

export default function ContentWrapper(props: Props): ReactNode {
  return (
    <>
      <Content {...props} />
      <ExpandCollapseButton />
    </>
  );
}
