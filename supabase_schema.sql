-- 藕叶英语学习追踪系统数据库结构

-- 1. 教师配置表
CREATE TABLE IF NOT EXISTS teacher_config (
    id INTEGER PRIMARY KEY DEFAULT 1,
    access_password TEXT NOT NULL DEFAULT 'sjdh4405',
    school_name TEXT DEFAULT '藕叶英语',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认配置
INSERT INTO teacher_config (id, access_password, school_name) 
VALUES (1, 'sjdh4405', '藕叶英语')
ON CONFLICT (id) DO NOTHING;

-- 2. 学生表
CREATE TABLE IF NOT EXISTS students (
    student_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    password TEXT NOT NULL,
    default_password TEXT DEFAULT '123456',
    is_password_changed BOOLEAN DEFAULT FALSE,
    target_score NUMERIC(2,1) DEFAULT 6.5 CHECK (target_score IN (6, 6.5, 7)),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. 模块达标标准表
CREATE TABLE IF NOT EXISTS pass_standards (
    id SERIAL PRIMARY KEY,
    module_type TEXT UNIQUE NOT NULL,
    module_name TEXT NOT NULL,
    score_6 NUMERIC(5,2) DEFAULT 70,
    score_6_5 NUMERIC(5,2) DEFAULT 80,
    score_7 NUMERIC(5,2) DEFAULT 95,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 插入默认的听力2400词标准
INSERT INTO pass_standards (module_type, module_name, score_6, score_6_5, score_7) VALUES
('dictation', '听力2400词', 70, 80, 95)
ON CONFLICT (module_type) DO NOTHING;

-- 4. 测试记录表
CREATE TABLE IF NOT EXISTS test_records (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES students(student_id),
    test_type TEXT NOT NULL CHECK (test_type IN ('random', 'wrong_words')),
    score NUMERIC(5,2) NOT NULL,
    correct_count INTEGER NOT NULL,
    total_count INTEGER NOT NULL,
    is_passed BOOLEAN NOT NULL,
    pass_threshold NUMERIC(5,2) NOT NULL,
    details JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. 错题本表
CREATE TABLE IF NOT EXISTS wrong_words (
    id SERIAL PRIMARY KEY,
    student_id TEXT NOT NULL REFERENCES students(student_id),
    word TEXT NOT NULL,
    wrong_count INTEGER DEFAULT 1,
    correct_streak INTEGER DEFAULT 0,
    last_tested TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_mastered BOOLEAN DEFAULT FALSE,
    UNIQUE(student_id, word)
);

-- 6. 创建索引
CREATE INDEX IF NOT EXISTS idx_test_records_student_id ON test_records(student_id);
CREATE INDEX IF NOT EXISTS idx_test_records_created_at ON test_records(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wrong_words_student_id ON wrong_words(student_id);
CREATE INDEX IF NOT EXISTS idx_wrong_words_is_mastered ON wrong_words(is_mastered);

-- 7. 启用 Row Level Security (RLS)
ALTER TABLE teacher_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE pass_standards ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE wrong_words ENABLE ROW LEVEL SECURITY;

-- 8. RLS 策略（允许所有操作，因为前端会用 service_role key）
-- 注意：生产环境应该更严格
CREATE POLICY "Allow all operations on teacher_config" ON teacher_config FOR ALL USING (true);
CREATE POLICY "Allow all operations on students" ON students FOR ALL USING (true);
CREATE POLICY "Allow all operations on pass_standards" ON pass_standards FOR ALL USING (true);
CREATE POLICY "Allow all operations on test_records" ON test_records FOR ALL USING (true);
CREATE POLICY "Allow all operations on wrong_words" ON wrong_words FOR ALL USING (true);
