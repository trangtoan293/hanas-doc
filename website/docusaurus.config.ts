import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Hanas Data Platform',
  tagline: 'Nền tảng Dữ liệu Hợp nhất - Data Lakehouse Platform',
  favicon: 'img/favicon.ico',

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
    image: 'img/hanas-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
      defaultMode: 'light',
    },
    navbar: {
      title: 'Hanas Data Platform',
      logo: {
        alt: 'Hanas Logo',
        src: 'img/logo.svg',
      },
      items: [],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Tài Liệu',
          items: [
            { label: 'Tổng Quan', to: '/overview' },
            { label: 'Kiến Trúc', to: '/overview/architecture' },
            { label: 'Quickstart', to: '/guides/quickstart' },
          ],
        },
        {
          title: 'Các Lớp',
          items: [
            { label: 'Thu Thập Dữ Liệu', to: '/ingestion' },
            { label: 'Lưu Trữ', to: '/storage' },
            { label: 'Xử Lý', to: '/processing' },
          ],
        },
      ],
      copyright: `© ${new Date().getFullYear()} Hanas Data Platform.`,
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
