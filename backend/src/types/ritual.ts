export interface Ritual {
  id?: string;
  user_id?: string;
  name: string;
  reminder_time?: string;
  reminder_days?: string[];
  created_at?: Date;
}

export interface RitualStep {
  id?: string;
  ritual_id: string;
  title: string;
  is_completed: boolean;
  order_index: number;
}
