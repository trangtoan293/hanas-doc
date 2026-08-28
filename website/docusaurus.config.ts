import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Hanas Data Platform',
  tagline: 'Nền tảng Dữ liệu Hợp nhất - Data Lakehouse Platform',
  favicon: 'img/katalyst-mark.svg',

  // Future flags
  future: {
    v4: {
      removeLegacyPostBuildHeadAttribute: true,
    },
    experimental_faster: {
      swcJsLoader: true,
      swcJsMinimizer: true,
      swcHtmlMinimizer: true,
      lightningCssMinimizer: true,
      rspackBundler: true,
    },
  },

  // Production URL
  url: 'https://hanas-docs.github.io',
  baseUrl: '/',

  // GitHub pages config
  organizationName: 'hanas',
  projectName: 'hanas-docs',

  onBrokenLinks: 'warn',

  // Internationalization - Vietnamese default
  i18n: {
    defaultLocale: 'vi',
    locales: ['vi'],
  },

  // Enable Mermaid
  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  themes: ['@docusaurus/theme-mermaid'],

  // Performance optimized font loading
  headTags: [
    {
      tagName: 'link',
      attributes: {
        rel: 'preconnect',
        href: 'https://fonts.googleapis.com',
      },
    },
    {
      tagName: 'link',
      attributes: {
        rel: 'preconnect',
        href: 'https://fonts.gstatic.com',
        crossorigin: 'anonymous',
      },
    },
  ],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://gitlab.katalyst.vn:7979/de-team/hanas-docs/-/blob/main/website/',
          // Training và maintenance là tài liệu nội bộ, không đưa vào public build/search.
          exclude: ['**/10-training/**', '**/11-maintenance/**'],
          routeBasePath: '/',
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
        },
        blog: false, // Disable blog for now
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  // Local search plugin configuration
  plugins: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        // Hashed filenames for cache busting
        hashed: true,
        // Language support: English and Vietnamese
        language: ['en', 'vi'],
        // Index documentation pages
        indexDocs: true,
        // Index blog pages (disabled since blog is false)
        indexBlog: false,
        // Index static pages
        indexPages: false,
        // Docs route base path
        docsRouteBasePath: '/',
        // Maximum search results to show
        // Maximum search results to show
        searchResultLimits: 10,
      },
    ],
  ],


  themeConfig: {
    image: 'img/katalyst-logo.svg',
    colorMode: {
      respectPrefersColorScheme: true,
      defaultMode: 'light',
    },
    navbar: {
      title: 'Hanas Data & AI',
      logo: {
        alt: 'Katalyst logo',
        src: 'img/katalyst-logo.svg',
      },
      items: [
        { label: 'Nền tảng', to: '/overview', position: 'left' },
        { label: 'Kiến trúc', to: '/overview/architecture', position: 'left' },
        { label: 'AI Services', to: '/ai-service', position: 'left' },
        { label: 'Tài liệu', to: '/guides', position: 'left' },
        {
          label: 'Hanas Portal ↗',
          href: 'https://portal.hanas.io/portal/home/dashboard',
          position: 'right',
          className: 'navbarPortal',
        },
      ],
    },
    footer: {
      style: 'dark',
      logo: {
        alt: 'Katalyst · Hanas Data & AI Platform',
        src: 'img/katalyst-logo.svg',
        href: '/',
        height: 28,
      },
      links: [
        {
          title: 'Nền tảng',
          items: [
            { label: 'Tổng Quan', to: '/overview' },
            { label: 'Kiến Trúc', to: '/overview/architecture' },
            { label: 'Dịch Vụ AI', to: '/ai-service' },
          ],
        },
        {
          title: 'Data Stack',
          items: [
            { label: 'Thu Thập Dữ Liệu', to: '/ingestion' },
            { label: 'Lưu Trữ', to: '/storage' },
            { label: 'Xử Lý', to: '/processing' },
          ],
        },
        {
          title: 'Tài nguyên',
          items: [
            { label: 'Quickstart', to: '/guides/quickstart' },
            { label: 'Hướng dẫn thực hành', to: '/guides' },
            { label: 'Quản trị dữ liệu', to: '/governance' },
          ],
        },
      ],
      copyright: `© ${new Date().getFullYear()} Katalyst · Hanas Data & AI Platform.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'python', 'yaml', 'json', 'sql'],
    },
    // Algolia DocSearch configuration - disabled temporarily
    // To enable: Apply for free at https://docsearch.algolia.com/apply/
    // Then replace YOUR_APP_ID and YOUR_SEARCH_API_KEY with real values
    /*
    // Search configuration
    algolia: {
      // The application ID provided by Algolia
      appId: 'YOUR_APP_ID',
      // Public API key: it is safe to commit it
      apiKey: 'YOUR_SEARCH_API_KEY',
      indexName: 'hanas-docs',
      contextualSearch: true,
    },
    */
  } satisfies Preset.ThemeConfig,
};

export default config;
