import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/__docusaurus/debug',
    component: ComponentCreator('/__docusaurus/debug', '5ff'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/config',
    component: ComponentCreator('/__docusaurus/debug/config', '5ba'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/content',
    component: ComponentCreator('/__docusaurus/debug/content', 'a2b'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/globalData',
    component: ComponentCreator('/__docusaurus/debug/globalData', 'c3c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/metadata',
    component: ComponentCreator('/__docusaurus/debug/metadata', '156'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/registry',
    component: ComponentCreator('/__docusaurus/debug/registry', '88c'),
    exact: true
  },
  {
    path: '/__docusaurus/debug/routes',
    component: ComponentCreator('/__docusaurus/debug/routes', '000'),
    exact: true
  },
  {
    path: '/api',
    component: ComponentCreator('/api', '24b'),
    exact: true
  },
  {
    path: '/docs',
    component: ComponentCreator('/docs', 'd17'),
    routes: [
      {
        path: '/docs',
        component: ComponentCreator('/docs', 'f20'),
        routes: [
          {
            path: '/docs',
            component: ComponentCreator('/docs', '863'),
            routes: [
              {
                path: '/docs/backend/architecture',
                component: ComponentCreator('/docs/backend/architecture', 'cdf'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/backend/database',
                component: ComponentCreator('/docs/backend/database', 'ca2'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/backend/setup',
                component: ComponentCreator('/docs/backend/setup', 'c6c'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/deployment',
                component: ComponentCreator('/docs/deployment', '8f8'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/features/ai-assistant',
                component: ComponentCreator('/docs/features/ai-assistant', '4d6'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/features/analytics',
                component: ComponentCreator('/docs/features/analytics', 'b97'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/features/authentication',
                component: ComponentCreator('/docs/features/authentication', 'cb4'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/features/gamification',
                component: ComponentCreator('/docs/features/gamification', 'dd2'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/features/notifications',
                component: ComponentCreator('/docs/features/notifications', '883'),
                exact: true
              },
              {
                path: '/docs/features/profile',
                component: ComponentCreator('/docs/features/profile', '8a7'),
                exact: true
              },
              {
                path: '/docs/features/rituals',
                component: ComponentCreator('/docs/features/rituals', '16a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/features/social',
                component: ComponentCreator('/docs/features/social', '765'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/intro',
                component: ComponentCreator('/docs/intro', '61d'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/mobile/architecture',
                component: ComponentCreator('/docs/mobile/architecture', '50c'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/mobile/setup',
                component: ComponentCreator('/docs/mobile/setup', 'e2f'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/mobile/user-flows',
                component: ComponentCreator('/docs/mobile/user-flows', '9fa'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/docs/roadmap',
                component: ComponentCreator('/docs/roadmap', 'ced'),
                exact: true,
                sidebar: "tutorialSidebar"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '/',
    component: ComponentCreator('/', '2e1'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
