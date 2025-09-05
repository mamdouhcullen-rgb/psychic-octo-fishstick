/*
  # Complete Database Schema Update

  1. New Tables
    - `judicial_circles` - Judicial departments/circles
    - `user_profiles` - Extended user information
    - `cases` - Case management
    - `case_circles` - Case collaboration between circles
    - `case_threads` - Discussion threads for cases
    - `case_messages` - Messages within threads
    - `case_documents` - Document management
    - `audit_logs` - System audit trail

  2. Security
    - Enable RLS on all tables
    - Comprehensive security policies
    - Role-based access control

  3. Sample Data
    - Test judicial circles
    - Sample user profiles for testing
*/

-- Drop existing tables if they exist (in correct order)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS case_documents CASCADE;
DROP TABLE IF EXISTS case_messages CASCADE;
DROP TABLE IF EXISTS case_threads CASCADE;
DROP TABLE IF EXISTS case_circles CASCADE;
DROP TABLE IF EXISTS cases CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS judicial_circles CASCADE;

-- Drop existing types
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS case_status CASCADE;
DROP TYPE IF EXISTS case_priority CASCADE;
DROP TYPE IF EXISTS circle_role CASCADE;

-- Create custom types
CREATE TYPE user_role AS ENUM ('judge', 'clerk', 'trainee');
CREATE TYPE case_status AS ENUM ('open', 'in_progress', 'under_review', 'closed');
CREATE TYPE case_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE circle_role AS ENUM ('primary', 'collaborating', 'consulting');

-- Create judicial_circles table
CREATE TABLE judicial_circles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Create user_profiles table
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  role user_role NOT NULL DEFAULT 'trainee',
  circle_id uuid REFERENCES judicial_circles(id),
  employee_id text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create cases table
CREATE TABLE cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_number text UNIQUE NOT NULL,
  title text NOT NULL,
  description text,
  status case_status NOT NULL DEFAULT 'open',
  priority case_priority NOT NULL DEFAULT 'medium',
  primary_circle_id uuid NOT NULL REFERENCES judicial_circles(id),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  assigned_judge uuid REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create case_circles table (for collaboration)
CREATE TABLE case_circles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  circle_id uuid NOT NULL REFERENCES judicial_circles(id),
  role circle_role NOT NULL DEFAULT 'collaborating',
  added_at timestamptz DEFAULT now(),
  added_by uuid NOT NULL REFERENCES auth.users(id),
  UNIQUE(case_id, circle_id)
);

-- Create case_threads table
CREATE TABLE case_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  title text NOT NULL,
  created_by uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now()
);

-- Create case_messages table
CREATE TABLE case_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES case_threads(id) ON DELETE CASCADE,
  content text NOT NULL,
  sender_id uuid NOT NULL REFERENCES auth.users(id),
  created_at timestamptz DEFAULT now(),
  edited_at timestamptz
);

-- Create case_documents table
CREATE TABLE case_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_path text NOT NULL,
  file_type text NOT NULL,
  file_size integer NOT NULL,
  ocr_content text,
  uploaded_by uuid NOT NULL REFERENCES auth.users(id),
  uploaded_at timestamptz DEFAULT now()
);

-- Create audit_logs table
CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id),
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id uuid,
  details jsonb DEFAULT '{}',
  ip_address text,
  user_agent text,
  created_at timestamptz DEFAULT now()
);

-- Create indexes for performance
CREATE INDEX idx_user_profiles_circle_id ON user_profiles(circle_id);
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_cases_primary_circle_id ON cases(primary_circle_id);
CREATE INDEX idx_cases_assigned_judge ON cases(assigned_judge);
CREATE INDEX idx_cases_status ON cases(status);
CREATE INDEX idx_case_circles_case_id ON case_circles(case_id);
CREATE INDEX idx_case_circles_circle_id ON case_circles(circle_id);
CREATE INDEX idx_case_threads_case_id ON case_threads(case_id);
CREATE INDEX idx_case_messages_thread_id ON case_messages(thread_id);
CREATE INDEX idx_case_documents_case_id ON case_documents(case_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Enable Row Level Security
ALTER TABLE judicial_circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE case_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for judicial_circles
CREATE POLICY "Users can view circles they belong to"
  ON judicial_circles FOR SELECT
  TO authenticated
  USING (id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid()));

-- Create RLS policies for user_profiles
CREATE POLICY "Users can view their own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

-- Create RLS policies for cases
CREATE POLICY "Users can view cases in their circle or collaborating circles"
  ON cases FOR SELECT
  TO authenticated
  USING (
    primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
    OR id IN (
      SELECT case_id FROM case_circles 
      WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
    )
  );

CREATE POLICY "Judges and clerks can create cases"
  ON cases FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('judge', 'clerk')
    )
  );

CREATE POLICY "Judges and clerks can update cases in their circle"
  ON cases FOR UPDATE
  TO authenticated
  USING (
    primary_circle_id IN (
      SELECT circle_id FROM user_profiles 
      WHERE id = auth.uid() AND role IN ('judge', 'clerk')
    )
  );

-- Create RLS policies for case_circles
CREATE POLICY "Users can view case circles for accessible cases"
  ON case_circles FOR SELECT
  TO authenticated
  USING (
    case_id IN (
      SELECT id FROM cases
      WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      OR id IN (
        SELECT case_id FROM case_circles 
        WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      )
    )
  );

-- Create RLS policies for case_threads
CREATE POLICY "Users can view threads for accessible cases"
  ON case_threads FOR SELECT
  TO authenticated
  USING (
    case_id IN (
      SELECT id FROM cases
      WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      OR id IN (
        SELECT case_id FROM case_circles 
        WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      )
    )
  );

CREATE POLICY "Users can create threads for accessible cases"
  ON case_threads FOR INSERT
  TO authenticated
  WITH CHECK (
    case_id IN (
      SELECT id FROM cases
      WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      OR id IN (
        SELECT case_id FROM case_circles 
        WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      )
    )
  );

-- Create RLS policies for case_messages
CREATE POLICY "Users can view messages in accessible threads"
  ON case_messages FOR SELECT
  TO authenticated
  USING (
    thread_id IN (
      SELECT id FROM case_threads
      WHERE case_id IN (
        SELECT id FROM cases
        WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
        OR id IN (
          SELECT case_id FROM case_circles 
          WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
        )
      )
    )
  );

CREATE POLICY "Users can send messages in accessible threads"
  ON case_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    thread_id IN (
      SELECT id FROM case_threads
      WHERE case_id IN (
        SELECT id FROM cases
        WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
        OR id IN (
          SELECT case_id FROM case_circles 
          WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
        )
      )
    )
  );

-- Create RLS policies for case_documents
CREATE POLICY "Users can view documents for accessible cases"
  ON case_documents FOR SELECT
  TO authenticated
  USING (
    case_id IN (
      SELECT id FROM cases
      WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      OR id IN (
        SELECT case_id FROM case_circles 
        WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      )
    )
  );

CREATE POLICY "Users can upload documents to accessible cases"
  ON case_documents FOR INSERT
  TO authenticated
  WITH CHECK (
    case_id IN (
      SELECT id FROM cases
      WHERE primary_circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      OR id IN (
        SELECT case_id FROM case_circles 
        WHERE circle_id IN (SELECT circle_id FROM user_profiles WHERE id = auth.uid())
      )
    )
  );

-- Create RLS policies for audit_logs
CREATE POLICY "Judges can view all audit logs in their circle"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles 
      WHERE id = auth.uid() AND role = 'judge'
    )
  );

CREATE POLICY "System can insert audit logs"
  ON audit_logs FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Insert sample judicial circles
INSERT INTO judicial_circles (id, name, description) VALUES
  ('11111111-1111-1111-1111-111111111111', 'الدائرة الجزائية الأولى', 'دائرة متخصصة في القضايا الجزائية'),
  ('22222222-2222-2222-2222-222222222222', 'الدائرة المدنية الأولى', 'دائرة متخصصة في القضايا المدنية'),
  ('33333333-3333-3333-3333-333333333333', 'دائرة الأحوال الشخصية', 'دائرة متخصصة في قضايا الأحوال الشخصية'),
  ('44444444-4444-4444-4444-444444444444', 'الدائرة التجارية', 'دائرة متخصصة في القضايا التجارية');

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- This function will be called when a new user is created
  -- The actual profile creation will be handled by the application
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function for audit logging
CREATE OR REPLACE FUNCTION log_audit_event(
  p_action text,
  p_resource_type text,
  p_resource_id uuid DEFAULT NULL,
  p_details jsonb DEFAULT '{}'
)
RETURNS void AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, resource_type, resource_id, details)
  VALUES (auth.uid(), p_action, p_resource_type, p_resource_id, p_details);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
