-- This is my University system that focuses more on the academic side
-- it uses PostgreSQL Object-Relational Database Implementation




-- S0: DROP ALL OBJECTS 
-- to ensure we start on a clean slate


DROP TABLE IF EXISTS enrollment       CASCADE;
DROP TABLE IF EXISTS course           CASCADE;
DROP TABLE IF EXISTS department       CASCADE;
DROP TABLE IF EXISTS lecturer         CASCADE;
DROP TABLE IF EXISTS administrator    CASCADE;
DROP TABLE IF EXISTS staff            CASCADE;
DROP TABLE IF EXISTS student          CASCADE;
DROP TABLE IF EXISTS person           CASCADE;

DROP TYPE  IF EXISTS address_type     CASCADE;
DROP TYPE  IF EXISTS qualification_type CASCADE;
DROP TYPE  IF EXISTS contact_type     CASCADE;
DROP TYPE  IF EXISTS grade_type       CASCADE;

DROP FUNCTION IF EXISTS fn_age_from_dob(DATE);
DROP FUNCTION IF EXISTS fn_enrollment_duration(INT);
DROP FUNCTION IF EXISTS fn_is_active_enrollment(TSTZRANGE);
DROP PROCEDURE IF EXISTS sp_enrollment_olap_report(INT);


-- S1: USER DEFINED TYPES

-- Composite type: structured address
CREATE TYPE address_type AS (
    street      VARCHAR(100),
    city        VARCHAR(60),
    postcode    VARCHAR(12),
    country     VARCHAR(60)
);

-- Composite type:  single academic/professional qualification
CREATE TYPE qualification_type AS (
    degree_title    VARCHAR(100),   -- e.g. 'PhD Computer Science'
    institution     VARCHAR(100),
    awarded_year    SMALLINT
);

-- Composite type: contact details
CREATE TYPE contact_type AS (
    phone   VARCHAR(20),
    email   VARCHAR(100)
);

-- Composite type: a grade record 
CREATE TYPE grade_type AS (
    component   VARCHAR(60),   -- e.g. 'Coursework', 'Exam'
    weight      NUMERIC(5,2),  -- percentage weight 0-100
    score       NUMERIC(5,2)   -- marks achieved 0-100
);


-- S2: BASE TABLE – person  (supertype)
-- The root of the Person hierarchy
-- student and staff REFERENCE person via FK (table-per-type inheritance).

CREATE TABLE person (
    person_id       SERIAL          PRIMARY KEY,
    person_type     VARCHAR(20)     NOT NULL
                        CHECK (person_type IN ('student','lecturer','administrator')),
    first_name      VARCHAR(60)     NOT NULL,
    last_name       VARCHAR(60)     NOT NULL,
    date_of_birth   DATE            NOT NULL,
    gender          CHAR(1)         CHECK (gender IN ('M','F','O')),
    address         address_type,           -- UDT composite column
    contact         contact_type,           -- UDT composite column
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Unique email enforced at person level using expression index
CREATE UNIQUE INDEX uix_person_email ON person (((contact).email));


-- S3: SUBTYPE – student


CREATE TABLE student (
    person_id           INT             PRIMARY KEY
                            REFERENCES person(person_id) ON DELETE CASCADE,
    student_number      VARCHAR(12)     NOT NULL UNIQUE,
    programme           VARCHAR(100)    NOT NULL,   -- e.g. 'BSc Computer Science'
    level               SMALLINT        NOT NULL CHECK (level BETWEEN 1 AND 8),
    admission_date      DATE            NOT NULL,
    expected_graduation DATE,
    scholarship_amount  NUMERIC(10,2)   DEFAULT 0.00,
    -- Temporal validity period for the student record
    valid_period        TSTZRANGE       NOT NULL
                            DEFAULT tstzrange(NOW(), NULL, '[)')
);

-- GiST index on temporal range for fast overlap queries
CREATE INDEX idx_student_valid ON student USING GIST (valid_period);


-- S4: SUBTYPE – staff  (intermediate supertype for lecturer or admin)

CREATE TABLE staff (
    person_id           INT             PRIMARY KEY
                            REFERENCES person(person_id) ON DELETE CASCADE,
    staff_number        VARCHAR(12)     NOT NULL UNIQUE,
    department_id       INT,            -- FK added after department table is created
    hire_date           DATE            NOT NULL,
    salary              NUMERIC(10,2)   NOT NULL CHECK (salary > 0),
    -- Array of qualifications (PostgreSQL native array of composite type)
    qualifications      qualification_type[],
    -- Employment period (temporal range)
    employment_period   TSTZRANGE       NOT NULL
                            DEFAULT tstzrange(NOW(), NULL, '[)')
);

CREATE INDEX idx_staff_emp ON staff USING GIST (employment_period);


-- S5: SUBTYPE of staff – lecturer

CREATE TABLE lecturer (
    person_id           INT             PRIMARY KEY
                            REFERENCES staff(person_id) ON DELETE CASCADE,
    academic_rank       VARCHAR(40)     NOT NULL
                            CHECK (academic_rank IN
                                ('Teaching Assistant','Lecturer','Senior Lecturer',
                                 'Associate Professor','Professor')),
    research_area       VARCHAR(120),
    -- Courses this lecturer is responsible for (resolved via course table)
    office_location     VARCHAR(40)
);


-- SECTION 6: SUBTYPE of staff – administrator

CREATE TABLE administrator (
    person_id           INT             PRIMARY KEY
                            REFERENCES staff(person_id) ON DELETE CASCADE,
    admin_role          VARCHAR(60)     NOT NULL,   -- e.g. 'Registry Officer'
    manages_department  INT             -- self-referential to department (FK added later)
);


-- S7: department
-- To Aggregatee courses. staff belong to departments


CREATE TABLE department (
    department_id   SERIAL          PRIMARY KEY,
    dept_name       VARCHAR(100)    NOT NULL UNIQUE,
    dept_code       VARCHAR(10)     NOT NULL UNIQUE,
    building        VARCHAR(60),
    established_on  DATE,
    head_of_dept    INT             -- FK -> staff.person_id (added after staff exists)
);

-- Now here i'm gonna add the FK from staff -> department
ALTER TABLE staff
    ADD CONSTRAINT fk_staff_dept
    FOREIGN KEY (department_id) REFERENCES department(department_id);

-- And administrator -> department
ALTER TABLE administrator
    ADD CONSTRAINT fk_admin_manages
    FOREIGN KEY (manages_department) REFERENCES department(department_id);

-- Then department head -> staff
ALTER TABLE department
    ADD CONSTRAINT fk_dept_head
    FOREIGN KEY (head_of_dept) REFERENCES staff(person_id);


-- S8: course
-- Owned by a department; links with a lecturer


CREATE TABLE course (
    course_id       SERIAL          PRIMARY KEY,
    course_code     VARCHAR(12)     NOT NULL UNIQUE,
    course_name     VARCHAR(120)    NOT NULL,
    credits         SMALLINT        NOT NULL CHECK (credits > 0),
    level           SMALLINT        NOT NULL CHECK (level BETWEEN 1 AND 8),
    department_id   INT             NOT NULL
                        REFERENCES department(department_id),
    lecturer_id     INT
                        REFERENCES lecturer(person_id),
    -- Temporal: when this course offering is available
    offering_period TSTZRANGE       NOT NULL
                        DEFAULT tstzrange(NOW(), NOW() + INTERVAL '1 year', '[)')
);

CREATE INDEX idx_course_offering ON course USING GIST (offering_period);


-- S9: enrollment
-- Here is where we link student and course; and then holds grade components as array

CREATE TABLE enrollment (
    enrollment_id   SERIAL          PRIMARY KEY,
    student_id      INT             NOT NULL
                        REFERENCES student(person_id) ON DELETE CASCADE,
    course_id       INT             NOT NULL
                        REFERENCES course(course_id),
    enrolled_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    completed_at    TIMESTAMPTZ,
    status          VARCHAR(20)     NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','completed','withdrawn','deferred')),
    -- Array of grade components via composite UDT array
    grade_components grade_type[],
    -- Temporal range for this enrollment
    enrollment_period TSTZRANGE     NOT NULL
                        DEFAULT tstzrange(NOW(), NULL, '[)'),
    UNIQUE (student_id, course_id)
);

CREATE INDEX idx_enrollment_period ON enrollment USING GIST (enrollment_period);

-- The computed final grade is derived from a stored function in that we'll do in S11


-- S10: DATA INTEGRITY TRIGGERS

-- Trigger 1: Ensure person_type is consistent with which subtype table is used
CREATE OR REPLACE FUNCTION trg_check_person_subtype()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- When inserting into student, person_type has to be 'student'
    IF TG_TABLE_NAME = 'student' THEN
        IF NOT EXISTS (
            SELECT 1 FROM person
            WHERE person_id = NEW.person_id AND person_type = 'student'
        ) THEN
            RAISE EXCEPTION
                'person_id % must have person_type=student before inserting into student table.',
                NEW.person_id;
        END IF;
    END IF;

    IF TG_TABLE_NAME = 'staff' THEN
        IF NOT EXISTS (
            SELECT 1 FROM person
            WHERE person_id = NEW.person_id
              AND person_type IN ('lecturer','administrator')
        ) THEN
            RAISE EXCEPTION
                'person_id % must have person_type in (lecturer,administrator) before inserting into staff table.',
                NEW.person_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_student_subtype_check
    BEFORE INSERT OR UPDATE ON student
    FOR EACH ROW EXECUTE FUNCTION trg_check_person_subtype();

CREATE TRIGGER trg_staff_subtype_check
    BEFORE INSERT OR UPDATE ON staff
    FOR EACH ROW EXECUTE FUNCTION trg_check_person_subtype();

-- Trigger 2: Prevent enrolling a student in a course outside their level range
--            (students may enrol ±1 level from their programme level)
CREATE OR REPLACE FUNCTION trg_check_enrollment_level()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_student_level SMALLINT;
    v_course_level  SMALLINT;
BEGIN
    SELECT s.level INTO v_student_level
    FROM student s WHERE s.person_id = NEW.student_id;

    SELECT c.level INTO v_course_level
    FROM course c WHERE c.course_id = NEW.course_id;

    IF ABS(v_student_level - v_course_level) > 1 THEN
        RAISE EXCEPTION
            'Student level % cannot enrol in course level %. Difference must be ≤ 1.',
            v_student_level, v_course_level;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enrollment_level_check
    BEFORE INSERT ON enrollment
    FOR EACH ROW EXECUTE FUNCTION trg_check_enrollment_level();

-- Trigger 3: Automatically set completed_at when status changes to 'completed'
CREATE OR REPLACE FUNCTION trg_set_completed_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
        NEW.completed_at := NOW();
        NEW.enrollment_period :=
            tstzrange(lower(OLD.enrollment_period), NOW(), '[)');
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_auto_completed_at
    BEFORE UPDATE ON enrollment
    FOR EACH ROW EXECUTE FUNCTION trg_set_completed_at();

-- Trigger 4: Salary must not be reduced by more than 20% in a single update
CREATE OR REPLACE FUNCTION trg_salary_reduction_check()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.salary < OLD.salary * 0.80 THEN
        RAISE EXCEPTION
            'Salary reduction of more than 20%% is not permitted. Old: %, New: %',
            OLD.salary, NEW.salary;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_salary_protect
    BEFORE UPDATE OF salary ON staff
    FOR EACH ROW EXECUTE FUNCTION trg_salary_reduction_check();

-- S11: STORED FUNCTIONS

-- Function A: Calculate age in years from a date of birth
CREATE OR REPLACE FUNCTION fn_age_from_dob(p_dob DATE)
RETURNS INT LANGUAGE plpgsql AS $$
BEGIN
    RETURN DATE_PART('year', AGE(CURRENT_DATE, p_dob))::INT;
END;
$$;

-- Function B: Return enrollment duration as an interval description
--             Requires enrollment_id; uses temporal range arithmetic
CREATE OR REPLACE FUNCTION fn_enrollment_duration(p_enrollment_id INT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_start     TIMESTAMPTZ;
    v_end       TIMESTAMPTZ;
    v_interval  INTERVAL;
    v_days      INT;
    v_months    INT;
BEGIN
    SELECT lower(enrollment_period),
           COALESCE(upper(enrollment_period), NOW())
    INTO   v_start, v_end
    FROM   enrollment
    WHERE  enrollment_id = p_enrollment_id;

    IF NOT FOUND THEN
        RETURN 'Enrollment not found';
    END IF;

    v_interval := v_end - v_start;
    v_months   := EXTRACT(YEAR  FROM v_interval)::INT * 12
                + EXTRACT(MONTH FROM v_interval)::INT;
    v_days     := EXTRACT(DAY   FROM v_interval)::INT;

    RETURN v_months || ' month(s) and ' || v_days || ' day(s)';
END;
$$;

-- Function C: Check if an enrollment is currently active (temporal overlap)
CREATE OR REPLACE FUNCTION fn_is_active_enrollment(p_period TSTZRANGE)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    RETURN p_period @> NOW();  -- @> = contains operator on range
END;
$$;


-- S12: STORED PROCEDURE (OLAP query for Task 5e)

CREATE OR REPLACE PROCEDURE sp_enrollment_olap_report(p_min_enrollments INT DEFAULT 1)
LANGUAGE plpgsql AS $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '=== ENROLLMENT OLAP REPORT (min enrollments: %) ===', p_min_enrollments;
    RAISE NOTICE '%-30s %-25s %-10s %-12s',
        'Department', 'Programme', 'Level', 'Enrollments';
    RAISE NOTICE '%', REPEAT('-', 82);

    FOR rec IN
        WITH olap_data AS (
            SELECT
                d.dept_name,
                s.programme,
                s.level                     AS student_level,
                COUNT(e.enrollment_id)      AS enrollment_count,
                ROUND(AVG(
                    (SELECT COALESCE(AVG(gc.score), 0)
                     FROM   UNNEST(e.grade_components) AS gc)
                ), 2)                       AS avg_score,
                -- ROLLUP across dept_name, programme, student_level
                GROUPING(d.dept_name)       AS grp_dept,
                GROUPING(s.programme)       AS grp_prog,
                GROUPING(s.level)           AS grp_level
            FROM       enrollment  e
            JOIN       student     s ON s.person_id   = e.student_id
            JOIN       course      c ON c.course_id   = e.course_id
            JOIN       department  d ON d.department_id = c.department_id
            GROUP BY ROLLUP(d.dept_name, s.programme, s.level)
        )
        SELECT *
        FROM   olap_data
        WHERE  enrollment_count >= p_min_enrollments
        ORDER BY grp_dept, grp_prog, grp_level, dept_name, programme, student_level
    LOOP
        RAISE NOTICE '%-30s %-25s %-10s %-12s',
            COALESCE(CASE WHEN rec.grp_dept = 1 THEN '** ALL DEPARTMENTS **'
                          ELSE rec.dept_name END, ''),
            COALESCE(CASE WHEN rec.grp_prog = 1 THEN '** ALL PROGRAMMES **'
                          ELSE rec.programme END, ''),
            COALESCE(CASE WHEN rec.grp_level = 1 THEN 'ALL'
                          ELSE rec.student_level::TEXT END, ''),
            rec.enrollment_count;
    END LOOP;
END;
$$;


-- S13: SAMPLE DATA

-- Persons

INSERT INTO person (person_type, first_name, last_name, date_of_birth, gender, address, contact)
VALUES
-- Students 
('student', 'Alice',   'Mokoena',   '2001-03-15', 'F',
    ROW('12 Jacaranda Ave','Gaborone','00267','Botswana')::address_type,
    ROW('+267-71234567','alice.mokoena@uni.ac.bw')::contact_type),

('student', 'Brian',   'Sithole',   '2000-07-22', 'M',
    ROW('45 Kgale Hill Rd','Gaborone','00267','Botswana')::address_type,
    ROW('+267-72345678','b.sithole@uni.ac.bw')::contact_type),

('student', 'Clara',   'Dlamini',   '2002-11-05', 'F',
    ROW('8 Tlokweng Rd','Gaborone','00268','Botswana')::address_type,
    ROW('+267-73456789','c.dlamini@uni.ac.bw')::contact_type),

('student', 'David',   'Nkosi',     '1999-01-30', 'M',
    ROW('22 Lobatse Rd','Kanye','00270','Botswana')::address_type,
    ROW('+267-74567890','d.nkosi@uni.ac.bw')::contact_type),

('student', 'Esi',     'Ofori',     '2003-06-18', 'F',
    ROW('3 Station Rd','Francistown','00271','Botswana')::address_type,
    ROW('+267-75678901','e.ofori@uni.ac.bw')::contact_type),

('student', 'Larona',    'Dichabeng',   '2001-07-19', 'F',
    ROW('15 Phase 2','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78123456','larona.dichabeng@uni.ac.bw')::contact_type),

('student', 'Mohuammed', 'Adnan',       '2002-02-11', 'M',
    ROW('22 Broadhurst','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78234567','mohuammed.adnan@uni.ac.bw')::contact_type),

('student', 'Ahmed',     'Salaam',      '2000-11-30', 'M',
    ROW('8 Village','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78345678','ahmed.salaam@uni.ac.bw')::contact_type),

('student', 'Sesame',    'Strawburt',   '2003-04-05', 'F',
    ROW('42 Extension 5','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78456789','sesame.strawburt@uni.ac.bw')::contact_type),

('student', 'Warona',    'Burner',      '2001-12-17', 'M',
    ROW('3 Mogoditshane','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78567890','warona.burner@uni.ac.bw')::contact_type),

('student', 'Kitso',     'Magang',      '2002-09-23', 'M',
    ROW('11 Phakalane','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78678901','kitso.magang@uni.ac.bw')::contact_type),

('student', 'Ofile',     'Lesotlho',    '2000-05-14', 'F',
    ROW('27 Tlokweng','Gaborone','00268','Botswana')::address_type,
    ROW('+267-78789012','ofile.lesotlho@uni.ac.bw')::contact_type),

('student', 'Tapiwa',    'Yuji',        '2003-08-27', 'M',
    ROW('9 Block 3','Lobatse','00270','Botswana')::address_type,
    ROW('+267-78890123','tapiwa.yuji@uni.ac.bw')::contact_type),

('student', 'Gojo',      'Gernash',     '2002-01-13', 'M',
    ROW('55 Gaborone West','Gaborone','00267','Botswana')::address_type,
    ROW('+267-78901234','gojo.gernash@uni.ac.bw')::contact_type),

('student', 'Saleem',    'Jobs',        '2001-06-21', 'M',
    ROW('14 Forest Hill','Gaborone','00267','Botswana')::address_type,
    ROW('+267-79012345','saleem.jobs@uni.ac.bw')::contact_type),

('student', 'Eli',       'Cinco',       '2000-10-09', 'M',
    ROW('2 Riverwalk','Gaborone','00267','Botswana')::address_type,
    ROW('+267-79123456','eli.cinco@uni.ac.bw')::contact_type),

('student', 'Thamaga',   'Motswapong',  '2004-03-03', 'M',
    ROW('19 Bontleng','Gaborone','00267','Botswana')::address_type,
    ROW('+267-79234567','thamaga.motswapong@uni.ac.bw')::contact_type),

('student', 'Derrick',   'Mudjana',     '2001-11-12', 'M',
    ROW('31 Extension 10','Gaborone','00267','Botswana')::address_type,
    ROW('+267-79345678','derrick.mudjana@uni.ac.bw')::contact_type),

('student', 'Thato',     'Molefhi',     '2002-07-07', 'F',
    ROW('7 Broadhurst','Gaborone','00267','Botswana')::address_type,
    ROW('+267-79456789','thato.molefhi@uni.ac.bw')::contact_type),

('student', 'Isheanesu', 'Nyangari',    '2001-09-18', 'M',
    ROW('23 Old Naledi','Gaborone','00267','Botswana')::address_type,
    ROW('+267-79567890','isheanesu.nyangari@uni.ac.bw')::contact_type),

-- Lecturers
('lecturer', 'Prof. James', 'Tlhong',  '1970-04-12', 'M',
    ROW('7 Stafford St','Gaborone','00267','Botswana')::address_type,
    ROW('+267-77111111','j.tlhong@uni.ac.bw')::contact_type),

('lecturer', 'Dr. Sarah',  'Mphathi', '1978-09-03', 'F',
    ROW('19 Broadhurst','Gaborone','00267','Botswana')::address_type,
    ROW('+267-77222222','s.mphathi@uni.ac.bw')::contact_type),

('lecturer', 'Dr. Kevin',  'Banda',   '1982-12-20', 'M',
    ROW('55 Extension 9','Gaborone','00267','Botswana')::address_type,
    ROW('+267-77333333','k.banda@uni.ac.bw')::contact_type),

-- Administrators
('administrator', 'Mary', 'Gabana',  '1985-05-25', 'F',
    ROW('10 Government Enclave','Gaborone','00267','Botswana')::address_type,
    ROW('+267-77444444','m.gabana@uni.ac.bw')::contact_type),

('administrator', 'John', 'Seretse', '1980-08-14', 'M',
    ROW('33 Commerce Park','Gaborone','00267','Botswana')::address_type,
    ROW('+267-77555555','j.seretse@uni.ac.bw')::contact_type);

-- Students (person_id 1-20)
INSERT INTO student (person_id, student_number, programme, level, admission_date, expected_graduation, scholarship_amount, valid_period)
VALUES
(1, 'STU2021001', 'BSc Computer Science',         3, '2021-09-01', '2024-06-30', 2500.00, tstzrange('2021-09-01','2024-06-30','[)')),
(2, 'STU2020002', 'BSc Information Systems',      3, '2020-09-01', '2023-06-30', 0.00,    tstzrange('2020-09-01','2023-06-30','[)')),
(3, 'STU2022003', 'BSc Computer Science',         2, '2022-09-01', '2025-06-30', 1500.00, tstzrange('2022-09-01','2025-06-30','[)')),
(4, 'STU2019004', 'MSc Data Science',             7, '2019-09-01', '2023-06-30', 5000.00, tstzrange('2019-09-01','2023-06-30','[)')),
(5, 'STU2023005', 'BSc Software Engineering',     1, '2023-09-01', '2026-06-30', 0.00,    tstzrange('2023-09-01','2026-06-30','[)')),
(6, 'STU2024030', 'BSc Computer Science',         1, '2024-09-01', '2027-06-30', 1200.00, tstzrange('2024-09-01', NULL, '[)')),
(7, 'STU2024031', 'BSc Information Systems',      1, '2024-09-01', '2027-06-30', 0.00,    tstzrange('2024-09-01', NULL, '[)')),
(8, 'STU2024032', 'BSc Software Engineering',     2, '2023-09-01', '2026-06-30', 800.00,  tstzrange('2023-09-01', NULL, '[)')),
(9, 'STU2024033', 'BSc Data Science',             1, '2024-09-01', '2027-06-30', 2000.00, tstzrange('2024-09-01', NULL, '[)')),
(10,'STU2024034', 'BSc Computer Science',         2, '2023-09-01', '2026-06-30', 0.00,    tstzrange('2023-09-01', NULL, '[)')),
(11,'STU2024035', 'BSc Information Systems',      3, '2022-09-01', '2025-06-30', 1500.00, tstzrange('2022-09-01','2025-06-30','[)')),
(12,'STU2024036', 'BSc Software Engineering',     2, '2023-09-01', '2026-06-30', 500.00,  tstzrange('2023-09-01', NULL, '[)')),
(13,'STU2024037', 'BSc Data Science',             1, '2024-09-01', '2027-06-30', 0.00,    tstzrange('2024-09-01', NULL, '[)')),
(14,'STU2024038', 'BSc Computer Science',         2, '2023-09-01', '2026-06-30', 1300.00, tstzrange('2023-09-01', NULL, '[)')),
(15,'STU2024039', 'BSc Information Systems',      3, '2022-09-01', '2025-06-30', 0.00,    tstzrange('2022-09-01','2025-06-30','[)')),
(16,'STU2024040', 'BSc Software Engineering',     1, '2024-09-01', '2027-06-30', 2200.00, tstzrange('2024-09-01', NULL, '[)')),
(17,'STU2024041', 'BSc Data Science',             2, '2023-09-01', '2026-06-30', 0.00,    tstzrange('2023-09-01', NULL, '[)')),
(18,'STU2024042', 'BSc Computer Science',         1, '2024-09-01', '2027-06-30', 750.00,  tstzrange('2024-09-01', NULL, '[)')),
(19,'STU2024043', 'BSc Information Systems',      2, '2023-09-01', '2026-06-30', 900.00,  tstzrange('2023-09-01', NULL, '[)')),
(20,'STU2024044', 'BSc Software Engineering',     3, '2022-09-01', '2025-06-30', 0.00,    tstzrange('2022-09-01','2025-06-30','[)'));

-- Departments 

INSERT INTO department (dept_name, dept_code, building, established_on)
VALUES
('Computer Science',         'CS',   'Science Block A', '1995-01-15'),
('Information Systems',      'IS',   'Commerce Block B', '1998-03-01'),
('Mathematics & Statistics', 'MATH', 'Science Block B',  '1990-06-20');

-- dept IDs: CS=1, IS=2, MATH=3

-- Staff
-- person_ids: lecturers: 21,22,23; administrators: 24,25 (using IDs after students)

INSERT INTO staff (person_id, staff_number, department_id, hire_date, salary, qualifications, employment_period)
VALUES
(21, 'STF1001', 1, '2005-08-01', 95000.00,
    ARRAY[
        ROW('PhD Computer Science','University of Cape Town',2004)::qualification_type,
        ROW('MSc Artificial Intelligence','UCT',2000)::qualification_type
    ],
    tstzrange('2005-08-01', NULL, '[)')),

(22, 'STF1002', 1, '2010-01-15', 72000.00,
    ARRAY[
        ROW('PhD Information Retrieval','University of Botswana',2009)::qualification_type,
        ROW('BSc Computer Science','University of Botswana',2003)::qualification_type
    ],
    tstzrange('2010-01-15', NULL, '[)')),

(23, 'STF1003', 2, '2015-07-01', 68000.00,
    ARRAY[
        ROW('PhD Information Systems','Wits University',2014)::qualification_type
    ],
    tstzrange('2015-07-01', NULL, '[)')),

(24, 'STF2001', 1, '2012-03-01', 52000.00,
    ARRAY[
        ROW('MBA Management','University of Botswana',2011)::qualification_type
    ],
    tstzrange('2012-03-01', NULL, '[)')),

(25, 'STF2002', 2, '2018-06-01', 49000.00,
    ARRAY[
        ROW('PGDip Academic Administration','Wits University',2017)::qualification_type
    ],
    tstzrange('2018-06-01', NULL, '[)'));

-- Lecturers 

INSERT INTO lecturer (person_id, academic_rank, research_area, office_location)
VALUES
(21, 'Professor',       'Artificial Intelligence & Machine Learning', 'SA-201'),
(22, 'Senior Lecturer', 'Database Systems & Information Retrieval',   'SA-202'),
(23, 'Lecturer',        'Enterprise Information Systems',             'CB-115');

-- Administrators 

INSERT INTO administrator (person_id, admin_role, manages_department)
VALUES
(24, 'Head of Registry',      1),
(25, 'Departmental Secretary', 2);

-- Department heads 

UPDATE department SET head_of_dept = 21 WHERE department_id = 1;
UPDATE department SET head_of_dept = 23 WHERE department_id = 2;
-- MATH dept head left NULL (vacant)

-- Courses 

INSERT INTO course (course_code, course_name, credits, level, department_id, lecturer_id, offering_period)
VALUES
('CS301', 'Database Systems',            20, 3, 1, 22,
    tstzrange('2023-09-01','2024-06-30','[)')),
('CS302', 'Artificial Intelligence',     20, 3, 1, 21,
    tstzrange('2023-09-01','2024-06-30','[)')),
('CS201', 'Data Structures & Algorithms',20, 2, 1, 22,
    tstzrange('2023-09-01','2024-06-30','[)')),
('IS301', 'Enterprise Systems',          20, 3, 2, 23,
    tstzrange('2023-09-01','2024-06-30','[)')),
('IS401', 'IT Project Management',       20, 6, 2, 23,
    tstzrange('2023-09-01','2024-06-30','[)')),
('CS701', 'Advanced Machine Learning',   30, 7, 1, 21,
    tstzrange('2023-09-01','2024-06-30','[)'));

-- course IDs: CS301=1, CS302=2, CS201=3, IS301=4, IS401=5, CS701=6

-- Enrollments (original 5 students)
INSERT INTO enrollment (student_id, course_id, status, grade_components, enrollment_period)
VALUES
-- Alice (level 3) -> CS301, CS302, IS301
(1, 1, 'completed',
    ARRAY[
        ROW('Coursework', 40.00, 35.50)::grade_type,
        ROW('Exam',       60.00, 52.00)::grade_type
    ],
    tstzrange('2023-09-01','2024-01-31','[)')),

(1, 2, 'completed',
    ARRAY[
        ROW('Coursework', 40.00, 38.00)::grade_type,
        ROW('Exam',       60.00, 55.00)::grade_type
    ],
    tstzrange('2023-09-01','2024-01-31','[)')),

(1, 4, 'active',
    ARRAY[
        ROW('Coursework', 40.00, 30.00)::grade_type
    ],
    tstzrange('2024-02-01', NULL, '[)')),

-- Brian (level 3) -> CS301, IS301
(2, 1, 'completed',
    ARRAY[
        ROW('Coursework', 40.00, 28.00)::grade_type,
        ROW('Exam',       60.00, 40.00)::grade_type
    ],
    tstzrange('2023-09-01','2024-01-31','[)')),

(2, 4, 'completed',
    ARRAY[
        ROW('Coursework', 40.00, 36.00)::grade_type,
        ROW('Exam',       60.00, 50.00)::grade_type
    ],
    tstzrange('2023-09-01','2024-01-31','[)')),

-- Clara (level 2) -> CS201, CS301 (level ±1)
(3, 3, 'active',
    ARRAY[
        ROW('Coursework', 40.00, 37.00)::grade_type,
        ROW('Exam',       60.00, 48.00)::grade_type
    ],
    tstzrange('2023-09-01', NULL, '[)')),

(3, 1, 'active',
    ARRAY[
        ROW('Coursework', 40.00, 34.00)::grade_type
    ],
    tstzrange('2024-02-01', NULL, '[)')),

-- David (level 7) -> CS701, IS401 (level ±1 = 6-8)
(4, 6, 'completed',
    ARRAY[
        ROW('Thesis Proposal',  30.00, 27.00)::grade_type,
        ROW('Written Exam',     40.00, 36.00)::grade_type,
        ROW('Viva',             30.00, 28.00)::grade_type
    ],
    tstzrange('2023-09-01','2024-03-31','[)')),

(4, 5, 'completed',
    ARRAY[
        ROW('Coursework', 40.00, 38.00)::grade_type,
        ROW('Exam',       60.00, 54.00)::grade_type
    ],
    tstzrange('2023-09-01','2024-01-31','[)')),

-- Esi (level 1) -> CS201 (level ±1 = 1-2)
(5, 3, 'active',
    ARRAY[
        ROW('Coursework', 40.00, 20.00)::grade_type
    ],
    tstzrange('2023-09-01', NULL, '[)'));

-- Other enrollments (i expanded the enrollment list because i felt 5 was too little)
INSERT INTO enrollment (student_id, course_id, status, grade_components, enrollment_period) VALUES
-- Level 1 students (6,7,9,13,16,18) -> courses level 1 or 2 
(6, 3, 'active', ARRAY[ROW('Coursework',40,32)::grade_type, ROW('Exam',60,48)::grade_type], tstzrange('2024-09-01',NULL,'[)')),
(7, 3, 'active', ARRAY[ROW('Coursework',40,36)::grade_type], tstzrange('2024-09-01',NULL,'[)')),
(9, 3, 'completed', ARRAY[ROW('Coursework',40,38)::grade_type, ROW('Exam',60,56)::grade_type], tstzrange('2023-09-01','2024-01-31','[)')),
(13,3, 'active', ARRAY[ROW('Coursework',40,30)::grade_type], tstzrange('2024-09-01',NULL,'[)')),
(16,3, 'active', ARRAY[ROW('Coursework',40,34)::grade_type, ROW('Exam',60,52)::grade_type], tstzrange('2024-09-01',NULL,'[)')),
(18,3, 'active', ARRAY[ROW('Coursework',40,35)::grade_type], tstzrange('2024-09-01',NULL,'[)')),

-- Level 2 students (8,10,12,14,17,19) -> course level 2 or 3
(8, 3, 'active', ARRAY[ROW('Coursework',40,33)::grade_type, ROW('Exam',60,51)::grade_type], tstzrange('2023-09-01',NULL,'[)')),
(8, 1, 'completed', ARRAY[ROW('Coursework',40,37)::grade_type, ROW('Exam',60,55)::grade_type], tstzrange('2023-09-01','2024-01-31','[)')),
(10,2, 'active', ARRAY[ROW('Coursework',40,30)::grade_type], tstzrange('2024-02-01',NULL,'[)')),
(12,4, 'active', ARRAY[ROW('Coursework',40,36)::grade_type, ROW('Exam',60,54)::grade_type], tstzrange('2023-09-01',NULL,'[)')),
(14,1, 'active', ARRAY[ROW('Coursework',40,34)::grade_type], tstzrange('2024-02-01',NULL,'[)')),
(17,2, 'active', ARRAY[ROW('Coursework',40,32)::grade_type, ROW('Exam',60,50)::grade_type], tstzrange('2024-02-01',NULL,'[)')),
(19,3, 'active', ARRAY[ROW('Coursework',40,38)::grade_type], tstzrange('2024-09-01',NULL,'[)')),

-- Level 3 students (11,15,20) -> course level 2,3 or 4.
(11,1, 'active', ARRAY[ROW('Coursework',40,35)::grade_type, ROW('Exam',60,53)::grade_type], tstzrange('2024-02-01',NULL,'[)')),
(11,4, 'active', ARRAY[ROW('Coursework',40,33)::grade_type], tstzrange('2024-09-01',NULL,'[)')),
(15,2, 'completed', ARRAY[ROW('Coursework',40,39)::grade_type, ROW('Exam',60,57)::grade_type], tstzrange('2023-09-01','2024-01-31','[)')),
(20,3, 'active', ARRAY[ROW('Coursework',40,31)::grade_type, ROW('Exam',60,49)::grade_type], tstzrange('2024-09-01',NULL,'[)'));

-- Marking completed enrollments for new students
UPDATE enrollment SET status = 'completed' 
WHERE (student_id, course_id) IN ((9,3), (8,1), (15,2))
AND status != 'completed';

-- Marking original completed enrollments (from earlier)
UPDATE enrollment SET status = 'completed' WHERE enrollment_id IN (1,2,4,5,8,9);

-- S14: QUERIES for Tasks 5a-e


-- 
-- QUERY 5a: JOINING  THREE OR MORE TABLES with multiple join types
--           + row restriction
-- Description:  this query is going to list all students currently enrolled in courses (active status),
-- showing student full name, programme, course name, course level, department name, and the lecturer responsible. It is done by using using  INNER JOIN (student-enrollment-course)
-- plus LEFT OUTER JOIN (course->lecturer, since a course may have no assigned lecturer) and INNER JOIN to department. Keeping the restriciton to active enrollments only.

SELECT
    p_stu.first_name || ' ' || p_stu.last_name   AS student_name,
    s.student_number,
    s.programme,
    c.course_code,
    c.course_name,
    c.level                                       AS course_level,
    d.dept_name                                   AS department,
    COALESCE(
        p_lec.first_name || ' ' || p_lec.last_name,
        'Unassigned'
    )                                             AS lecturer,
    e.status
FROM       enrollment    e
INNER JOIN student       s     ON s.person_id     = e.student_id
INNER JOIN person        p_stu ON p_stu.person_id = s.person_id
INNER JOIN course        c     ON c.course_id     = e.course_id
INNER JOIN department    d     ON d.department_id = c.department_id
LEFT  JOIN lecturer      lec   ON lec.person_id   = c.lecturer_id
LEFT  JOIN person        p_lec ON p_lec.person_id = lec.person_id
WHERE e.status = 'active'
ORDER BY student_name, c.course_code;

-- QUERY 5b: UNION operator across two different tables
-- Description: this query produces a combined directory of all academic staff (lecturers and administrators) with their rank, department, and contact email.
-- It uses UNION to merge results from the lecturer and administrator subtypes.Both sets come from different tables (lecturer JOIN staff JOIN person, and administrator JOIN staff JOIN person)
-- making this a true UNION across multiple distinct result sets. A MINUS portion then removes any record where the person has NO listed qualifications (staff with empty arrays).

-- Part 1: All lecturers with their rank and department
SELECT
    'Lecturer'                                      AS staff_category,
    p.first_name || ' ' || p.last_name             AS full_name,
    l.academic_rank                                 AS role_or_rank,
    d.dept_name                                     AS department,
    (p.contact).email                               AS email
FROM   lecturer    l
JOIN   staff       st ON st.person_id    = l.person_id
JOIN   person      p  ON p.person_id     = l.person_id
JOIN   department  d  ON d.department_id = st.department_id

UNION

-- Part 2: All administrators with their role and department
SELECT
    'Administrator'                                 AS staff_category,
    p.first_name || ' ' || p.last_name             AS full_name,
    a.admin_role                                    AS role_or_rank,
    d.dept_name                                     AS department,
    (p.contact).email                               AS email
FROM   administrator a
JOIN   staff         st ON st.person_id    = a.person_id
JOIN   person        p  ON p.person_id     = a.person_id
JOIN   department    d  ON d.department_id = st.department_id

ORDER BY staff_category, full_name;


-- QUERY 5c: Query using INHERITANCE / ARRAY 
-- Description: For each staff member,the query will unnest their qualifications array to list each qualification on its own row, showing the staff member's full
-- name, academic rank or admin role, and each qualification detail. This uses PostgreSQL UNNEST() on the qualification_type[] array column(equivalent of Oracle nested tables)
-- It also shows accessing inherited attributes since person.first_name is accessible for all subtypes via the shared person table.

SELECT
    p.first_name || ' ' || p.last_name     AS staff_name,
    p.person_type                           AS staff_type,
    COALESCE(l.academic_rank, a.admin_role) AS position,
    d.dept_name                             AS department,
    q.degree_title                          AS qualification,
    q.institution                           AS institution,
    q.awarded_year                          AS year_awarded
FROM       staff         st
JOIN       person        p  ON p.person_id     = st.person_id
JOIN       department    d  ON d.department_id = st.department_id
LEFT  JOIN lecturer      l  ON l.person_id     = st.person_id
LEFT  JOIN administrator a  ON a.person_id     = st.person_id
CROSS JOIN LATERAL UNNEST(st.qualifications) AS q(degree_title, institution, awarded_year)
ORDER BY staff_name, q.awarded_year DESC;


-- QUERY 5d: TEMPORAL features + stored FUNCTION
-- Description: For all enrollments, compute temporal metrics using the fn_enrollment_duration() stored function and fn_age_from_dob() function.
-- It's gonna shows student name, course, enrollment duration (via stored function), student age at time of enrollment (temporal arithmetic using AGE() with the tstzrange lower bound),
-- and whether the enrollment is currently active using the fn_is_active_enrollment() function.
-- It uses EXTRACT and INTERVAL arithmetic for interval-based reasoning

SELECT
    p.first_name || ' ' || p.last_name                          AS student_name,
    c.course_name,
    e.status,
    fn_enrollment_duration(e.enrollment_id)                      AS duration,
    fn_is_active_enrollment(e.enrollment_period)                 AS currently_active,
    -- Age of student when they enrolled (temporal arithmetic)
    DATE_PART('year',
        AGE(lower(e.enrollment_period)::DATE, p.date_of_birth)
    )::INT                                                       AS age_at_enrollment,
    -- How long ago (in months) the enrollment started
    EXTRACT(EPOCH FROM (NOW() - lower(e.enrollment_period)))
        / (60*60*24*30.44)                                       AS months_since_enrollment,
    -- Timestamp of enrollment start, formatted
    TO_CHAR(lower(e.enrollment_period), 'DD Mon YYYY HH24:MI')  AS enrolled_on
FROM       enrollment  e
JOIN       student     s  ON s.person_id  = e.student_id
JOIN       person      p  ON p.person_id  = s.person_id
JOIN       course      c  ON c.course_id  = e.course_id
ORDER BY lower(e.enrollment_period) DESC;


-- QUERY 5e: OLAP – ROLLUP inside a stored procedure
-- Description: This one calls the stored procedure sp_enrollment_olap_report() which internally runs a GROUP BY ROLLUP across three dimensions: department, programme, and student level.
-- It produces subtotals and grand totals. The procedure accepts a minimum enrollment threshold parameter.

CALL sp_enrollment_olap_report(1);

--We can also view the OLAP result as a SELECT (for output verification):
SELECT
    COALESCE(d.dept_name,       '** ALL DEPARTMENTS **') AS department,
    COALESCE(s.programme,       '** ALL PROGRAMMES **')  AS programme,
    COALESCE(s.level::TEXT,     '** ALL LEVELS **')      AS student_level,
    COUNT(e.enrollment_id)                               AS total_enrollments,
    ROUND(AVG(
        (SELECT COALESCE(AVG(gc.score), 0)
         FROM   UNNEST(e.grade_components) AS gc)
    ), 2)                                                AS avg_component_score
FROM       enrollment  e
JOIN       student     s  ON s.person_id     = e.student_id
JOIN       course      c  ON c.course_id     = e.course_id
JOIN       department  d  ON d.department_id = c.department_id
GROUP BY ROLLUP(d.dept_name, s.programme, s.level)
ORDER BY
    GROUPING(d.dept_name),
    GROUPING(s.programme),
    GROUPING(s.level),
    d.dept_name,
    s.programme,
    s.level;