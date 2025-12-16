/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  tutorialSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Backend',
      items: ['backend/setup', 'backend/architecture', 'backend/database'],
    },
    {
      type: 'category',
      label: 'Mobile App',
      items: ['mobile/setup', 'mobile/architecture', 'mobile/user-flows'],
    },
    {
      type: 'category',
      label: 'Features',
      items: [
        'features/authentication',
        'features/gamification',
        'features/rituals',
        'features/social',
        'features/ai-assistant',
        'features/analytics',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: ['deployment', 'roadmap'],
    },
  ],
};

module.exports = sidebars;
