import swaggerJsdoc from 'swagger-jsdoc';
import dotenv from 'dotenv';

dotenv.config();

const port = process.env.PORT || 3000;

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Rituals App API',
      version: '1.0.0',
      description: 'Backend API documentation for the Rituals application.',
      contact: {
        name: 'API Support',
        email: 'support@rituals.app',
      },
    },
    servers: [
      {
        url: '/api',
        description: 'Default Server',
      },
    ],
    tags: [
      { name: 'Auth', description: 'User authentication and registration' },
      { name: 'Rituals', description: 'Ritual management operations' },
      { name: 'Gamification', description: 'XP, levels, badges and leaderboards' },
      { name: 'Partnerships', description: 'Co-op rituals and partner management' },
      { name: 'Sharing', description: 'Social sharing features' },
      { name: 'Push Notifications', description: 'FCM token and notification settings' },
      { name: 'Devices', description: 'Manage user devices' },
      { name: 'Profile', description: 'User profile and settings' },
      { name: 'Friends', description: 'Friend requests and list management' },
      { name: 'Notifications', description: 'In-app notifications history' },
      { name: 'Shop', description: 'Virtual items and shop operations' },
      { name: 'LLM Usage', description: 'AI usage tracking and quotas' },
      { name: 'Ritual Logs', description: 'Ritual completion history and logs' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            message: {
              type: 'string',
              example: 'Something went wrong'
            },
          },
        },
        AuthResponse: {
          type: 'object',
          properties: {
            token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' },
            user: { $ref: '#/components/schemas/User' },
          },
        },
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid', example: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' },
            email: { type: 'string', format: 'email', example: 'john@example.com' },
            name: { type: 'string', example: 'John Doe' },
            avatar: { type: 'string', nullable: true, example: 'https://api.dicebear.com/7.x/avataaars/svg?seed=John' },
          },
        },
        Ritual: {
          type: 'object',
          properties: {
            id: { type: 'integer', example: 1 },
            title: { type: 'string', example: 'Morning Meditation' },
            description: { type: 'string', example: '10 minutes of mindfulness' },
            frequency: { type: 'string', enum: ['daily', 'weekly'], example: 'daily' },
            is_completed: { type: 'boolean' },
            reminder_time: { type: 'string', format: 'time' },
          },
        },
      },
    },
    security: [
      {
        bearerAuth: [],
      },
    ],
  },
  apis: ['./src/routes/*.ts', './src/controllers/*.ts'], // Path to the API docs
};

const swaggerSpec = swaggerJsdoc(options);

export default swaggerSpec;
