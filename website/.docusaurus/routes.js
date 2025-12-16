import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/rituals_app_clean/api',
    component: ComponentCreator('/rituals_app_clean/api', 'be9'),
    exact: true
  },
  {
    path: '/rituals_app_clean/docs',
    component: ComponentCreator('/rituals_app_clean/docs', 'b80'),
    routes: [
      {
        path: '/rituals_app_clean/docs',
        component: ComponentCreator('/rituals_app_clean/docs', 'd92'),
        routes: [
          {
            path: '/rituals_app_clean/docs',
            component: ComponentCreator('/rituals_app_clean/docs', '602'),
            routes: [
              {
                path: '/rituals_app_clean/docs/backend/architecture',
                component: ComponentCreator('/rituals_app_clean/docs/backend/architecture', 'f85'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/backend/database',
                component: ComponentCreator('/rituals_app_clean/docs/backend/database', 'b59'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/backend/setup',
                component: ComponentCreator('/rituals_app_clean/docs/backend/setup', '26b'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/deployment',
                component: ComponentCreator('/rituals_app_clean/docs/deployment', '1ff'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/features/ai-assistant',
                component: ComponentCreator('/rituals_app_clean/docs/features/ai-assistant', 'd7a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/features/analytics',
                component: ComponentCreator('/rituals_app_clean/docs/features/analytics', '25e'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/features/authentication',
                component: ComponentCreator('/rituals_app_clean/docs/features/authentication', '230'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/features/gamification',
                component: ComponentCreator('/rituals_app_clean/docs/features/gamification', '0a3'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/features/notifications',
                component: ComponentCreator('/rituals_app_clean/docs/features/notifications', '68c'),
                exact: true
              },
              {
                path: '/rituals_app_clean/docs/features/profile',
                component: ComponentCreator('/rituals_app_clean/docs/features/profile', '18b'),
                exact: true
              },
              {
                path: '/rituals_app_clean/docs/features/rituals',
                component: ComponentCreator('/rituals_app_clean/docs/features/rituals', 'a7d'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/features/social',
                component: ComponentCreator('/rituals_app_clean/docs/features/social', '5cf'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/intro',
                component: ComponentCreator('/rituals_app_clean/docs/intro', '743'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/mobile/architecture',
                component: ComponentCreator('/rituals_app_clean/docs/mobile/architecture', '05e'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/mobile/setup',
                component: ComponentCreator('/rituals_app_clean/docs/mobile/setup', '50a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/mobile/user-flows',
                component: ComponentCreator('/rituals_app_clean/docs/mobile/user-flows', 'a47'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/rituals_app_clean/docs/roadmap',
                component: ComponentCreator('/rituals_app_clean/docs/roadmap', 'f71'),
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
    path: '/rituals_app_clean/',
    component: ComponentCreator('/rituals_app_clean/', 'a7b'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
