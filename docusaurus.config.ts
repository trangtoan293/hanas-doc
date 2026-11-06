import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Hanas Data Platform',
  tagline:
    process.env.DOCUSAURUS_CURRENT_LOCALE === 'en'
      ? 'Official documentation for Hanas Data Platform'
      : 'Tài liệu chính thức của Hanas Data Platform',
  favicon: 'img/katalyst-mark.svg',

  future: {
    v4: {removeLegacyPostBuildHeadAttribute: true},
    faster: true,
  },

  url: 'https://docs.hanas.io',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenAnchors: 'warn',

  i18n: {
    defaultLocale: 'vi',
    locales: ['vi', 'en'],
    localeConfigs: {
      vi: {label: 'Tiếng Việt', htmlLang: 'vi-VN'},
      en: {label: 'English', htmlLang: 'en-US'},
    },
  },

  markdown: {
    mermaid: true,
    hooks: {onBrokenMarkdownLinks: 'throw'},
  },
  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          showLastUpdateTime: true,
          // A section's index.md is its category landing page, so drop it from the generated item list.
          async sidebarItemsGenerator({defaultSidebarItemsGenerator, ...args}) {
            const items = await defaultSidebarItemsGenerator(args);
            return items.filter((item) => !(item.type === 'doc' && /(^|\/)index$/.test(item.id)));
          },
        },
        blog: false,
        theme: {customCss: './src/css/custom.css'},
      } satisfies Preset.Options,
    ],
  ],

  plugins: [
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      {
        hashed: true,
        language: ['en', 'vi'],
        docsRouteBasePath: '/',
        indexBlog: false,
        indexPages: false,
        searchResultLimits: 10,
      },
    ],
  ],

  themeConfig: {
    image: 'img/katalyst-logo.svg',
    colorMode: {respectPrefersColorScheme: true, defaultMode: 'light'},
    mermaid: {theme: {light: 'neutral', dark: 'dark'}},
    navbar: {
      title: 'Hanas Docs',
      logo: {alt: 'Hanas Data Platform', src: 'img/katalyst-logo.svg'},
      items: [
        {type: 'docSidebar', sidebarId: 'product', label: 'Sản phẩm', position: 'left'},
        {type: 'docSidebar', sidebarId: 'operate', label: 'Triển khai & Vận hành', position: 'left'},
        {type: 'docSidebar', sidebarId: 'develop', label: 'API & Tích hợp', position: 'left'},
        {type: 'docSidebar', sidebarId: 'reference', label: 'Tham chiếu', position: 'left'},
        {type: 'localeDropdown', position: 'right'},
      ],
    },
    footer: {
      style: 'dark',
      logo: {alt: 'Hanas Data Platform', src: 'img/katalyst-logo.svg', href: '/', height: 28},
      links: [
        {
          title: 'Bắt đầu',
          items: [
            {label: 'Giới thiệu', to: '/get-started/introduction'},
            {label: 'Kiến trúc', to: '/get-started/architecture'},
            {label: 'Quickstart', to: '/get-started/quickstart'},
          ],
        },
        {
          title: 'Sản phẩm',
          items: [
            {label: 'Query Engine', to: '/query'},
            {label: 'Ontology', to: '/ontology'},
            {label: 'Kapas AI', to: '/kapas'},
          ],
        },
        {
          title: 'Vận hành',
          items: [
            {label: 'Cài đặt', to: '/operate/install'},
            {label: 'Xác thực & SSO', to: '/operate/identity'},
            {label: 'Nâng cấp', to: '/operate/upgrade'},
          ],
        },
      ],
      copyright: `© ${new Date().getFullYear()} Katalyst · Hanas Data Platform`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'python', 'yaml', 'json', 'sql', 'java'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
