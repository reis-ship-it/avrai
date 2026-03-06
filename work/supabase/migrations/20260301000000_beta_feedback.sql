-- Create the beta_feedback table
CREATE TABLE IF NOT EXISTS public.beta_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.beta_feedback ENABLE ROW LEVEL SECURITY;

-- Users can insert their own feedback
CREATE POLICY "Users can insert their own feedback" ON public.beta_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can read their own feedback
CREATE POLICY "Users can read their own feedback" ON public.beta_feedback
    FOR SELECT USING (auth.uid() = user_id);

-- Admins can read all feedback (assuming users table has a role column, or we just rely on a function)
-- We will add a simple policy for admins based on user role if available, or just a placeholder for now
CREATE POLICY "Admins can read all feedback" ON public.beta_feedback
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );

-- Admins can update feedback status
CREATE POLICY "Admins can update feedback status" ON public.beta_feedback
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() AND users.role = 'admin'
        )
    );
