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

-- Admin access flows through the private control plane service role in beta.
DROP POLICY IF EXISTS "Admins can read all feedback" ON public.beta_feedback;
DROP POLICY IF EXISTS "Service role can read all feedback" ON public.beta_feedback;
CREATE POLICY "Service role can read all feedback" ON public.beta_feedback
    FOR SELECT USING ((SELECT auth.role()) = 'service_role');

-- Admins can update feedback status
DROP POLICY IF EXISTS "Admins can update feedback status" ON public.beta_feedback;
DROP POLICY IF EXISTS "Service role can update feedback status" ON public.beta_feedback;
CREATE POLICY "Service role can update feedback status" ON public.beta_feedback
    FOR UPDATE USING ((SELECT auth.role()) = 'service_role');
