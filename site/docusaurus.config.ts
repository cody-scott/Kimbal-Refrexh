import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Kimball Refresh',
  tagline: 'Dimensional modeling, the Kimball way — built in dbt on Snowflake',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  // GitHub Pages: https://cody-scott.github.io/Kimbal-Refrexh/
  url: 'https://cody-scott.github.io',
  baseUrl: '/Kimbal-Refrexh/',
  organizationName: 'cody-scott',
  projectName: 'Kimbal-Refrexh',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },
  themes: ['@docusaurus/theme-mermaid'],

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/cody-scott/Kimbal-Refrexh/tree/main/site/',
          showLastUpdateTime: false,
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 4,
    },
    navbar: {
      title: 'Kimball Refresh',
      logo: {
        alt: 'Star schema logo',
        src: 'img/logo.svg',
      },
      items: [
        {type: 'doc', docId: 'intro', label: 'Start', position: 'left'},
        {type: 'doc', docId: 'foundations/index', label: 'Curriculum', position: 'left'},
        {type: 'doc', docId: 'case-studies/index', label: 'Case Studies', position: 'left'},
        {type: 'doc', docId: 'practice/index', label: 'Practice', position: 'left'},
        {type: 'doc', docId: 'reference/techniques-index', label: 'Techniques Index', position: 'left'},
        {
          href: 'https://github.com/cody-scott/Kimbal-Refrexh',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Learn',
          items: [
            {label: 'Start here', to: '/'},
            {label: 'Four-step process', to: '/foundations/four-step-process'},
            {label: 'Kimball in dbt', to: '/dbt/index'},
          ],
        },
        {
          title: 'Kimball sources',
          items: [
            {
              label: 'Kimball Group techniques',
              href: 'https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/',
            },
            {
              label: 'The Data Warehouse Toolkit (3rd ed.)',
              href: 'https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/books/data-warehouse-dw-toolkit/',
            },
          ],
        },
        {
          title: 'Tooling',
          items: [
            {label: 'dbt docs', href: 'https://docs.getdbt.com/'},
            {label: 'Snowflake SQL reference', href: 'https://docs.snowflake.com/en/sql-reference'},
          ],
        },
      ],
      copyright: `A personal study companion to the Kimball Group's work. Not affiliated with the Kimball Group or Wiley. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['sql', 'yaml', 'bash', 'python'],
    },
    mermaid: {
      theme: {light: 'neutral', dark: 'dark'},
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
