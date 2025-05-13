-- Trip Plan Tables Structure

-- Main trips table to store trip information
CREATE TABLE public.trips (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  number_of_days INT NOT NULL,
  number_of_people TEXT,
  budget TEXT,
  summary TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  CONSTRAINT trips_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Create index on user_id for faster lookups
CREATE INDEX trips_user_id_idx ON public.trips(user_id);

-- Trip preferences (stored as array/json to simplify structure)
CREATE TABLE public.trip_preferences (
  id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  preference TEXT NOT NULL,
  CONSTRAINT trip_preferences_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);

-- Trip days
CREATE TABLE public.trip_days (
  id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  day_title TEXT NOT NULL,
  day_date TIMESTAMP WITH TIME ZONE,
  day_order INT NOT NULL,
  CONSTRAINT trip_days_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);

-- Trip activities (linked to days)
CREATE TABLE public.trip_activities (
  id SERIAL PRIMARY KEY,
  trip_day_id INT NOT NULL REFERENCES public.trip_days(id) ON DELETE CASCADE,
  time TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  activity_order INT NOT NULL,
  CONSTRAINT trip_activities_trip_day_id_fkey FOREIGN KEY (trip_day_id) REFERENCES public.trip_days(id)
);

-- Trip highlights (destinations)
CREATE TABLE public.trip_highlights (
  id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  rating FLOAT NOT NULL,
  image_url TEXT,
  CONSTRAINT trip_highlights_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);

-- Trip recommendations
CREATE TABLE public.trip_recommendations (
  id SERIAL PRIMARY KEY,
  trip_id INT NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_type TEXT NOT NULL,
  CONSTRAINT trip_recommendations_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id)
);

-- Enable RLS (Row Level Security)
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_highlights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_recommendations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own trips" 
  ON public.trips FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own trips" 
  ON public.trips FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trips" 
  ON public.trips FOR UPDATE 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own trips" 
  ON public.trips FOR DELETE 
  USING (auth.uid() = user_id);

-- Create policies for related tables to allow operations based on trip ownership
-- For trip_preferences
CREATE POLICY "Users can view their own trip preferences" 
  ON public.trip_preferences FOR SELECT 
  USING (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid()));

CREATE POLICY "Users can insert their own trip preferences" 
  ON public.trip_preferences FOR INSERT 
  WITH CHECK (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid()));

CREATE POLICY "Users can update their own trip preferences" 
  ON public.trip_preferences FOR UPDATE 
  USING (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid()));

CREATE POLICY "Users can delete their own trip preferences" 
  ON public.trip_preferences FOR DELETE 
  USING (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid()));

-- Similar policies for other related tables
-- For trip_days
CREATE POLICY "Users can perform all operations on their own trip days" 
  ON public.trip_days 
  USING (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid()));

-- For trip_activities
CREATE POLICY "Users can perform all operations on their own trip activities" 
  ON public.trip_activities 
  USING (EXISTS (
    SELECT 1 FROM public.trip_days d 
    JOIN public.trips t ON d.trip_id = t.id 
    WHERE d.id = trip_day_id AND t.user_id = auth.uid()
  ));

-- For trip_highlights
CREATE POLICY "Users can perform all operations on their own trip highlights" 
  ON public.trip_highlights 
  USING (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid()));

-- For trip_recommendations
CREATE POLICY "Users can perform all operations on their own trip recommendations" 
  ON public.trip_recommendations 
  USING (EXISTS (SELECT 1 FROM public.trips WHERE id = trip_id AND user_id = auth.uid())); 
