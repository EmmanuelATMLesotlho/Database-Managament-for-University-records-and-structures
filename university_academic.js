//this is the mongodb version of my university system that focuses on the academic side
//it needs a mongodbshell, i ran it in Mongosh in MongoDB Compass
//it can be scaled up by simpley adding more data to the collections(not at the collection level
//but at the data insertion level)

// 1. CREATE/USE DATABASE
db = db.getSiblingDB("university_academic");
db.dropDatabase();

// 2. CREATE COLLECTIONS
db.createCollection("students");
db.createCollection("staff");
db.createCollection("departments");
db.createCollection("courses");
db.createCollection("enrollments");

// 3. INSERTING DEPARTMENTS
db.departments.insertMany([
  {
    _id: 1,
    dept_name: "Computer Science",
    dept_code: "CS",
    building: "Science Block A",
    established_on: ISODate("1995-01-15"),
    head_of_dept: null
  },
  {
    _id: 2,
    dept_name: "Information Systems",
    dept_code: "IS",
    building: "Commerce Block B",
    established_on: ISODate("1998-03-01"),
    head_of_dept: null
  },
  {
    _id: 3,
    dept_name: "Mathematics & Statistics",
    dept_code: "MATH",
    building: "Science Block B",
    established_on: ISODate("1990-06-20"),
    head_of_dept: null
  }
]);

// 4. INSERTING STAFF (lecturers and administrators)
db.staff.insertMany([
  // Lecturers (type: "lecturer")
  {
    _id: 21,
    type: "lecturer",
    staff_number: "STF1001",
    department_id: 1,
    hire_date: ISODate("2005-08-01"),
    salary: 95000,
    qualifications: [
      { degree_title: "PhD Computer Science", institution: "University of Cape Town", awarded_year: 2004 },
      { degree_title: "MSc Artificial Intelligence", institution: "UCT", awarded_year: 2000 }
    ],
    employment_period: { start: ISODate("2005-08-01"), end: null },
    personal: {
      first_name: "Prof. James",
      last_name: "Tlhong",
      date_of_birth: ISODate("1970-04-12"),
      gender: "M",
      address: { street: "7 Stafford St", city: "Gaborone", postcode: "00267", country: "Botswana" },
      contact: { phone: "+267-77111111", email: "j.tlhong@uni.ac.bw" }
    },
    academic_rank: "Professor",
    research_area: "Artificial Intelligence & Machine Learning",
    office_location: "SA-201"
  },
  {
    _id: 22,
    type: "lecturer",
    staff_number: "STF1002",
    department_id: 1,
    hire_date: ISODate("2010-01-15"),
    salary: 72000,
    qualifications: [
      { degree_title: "PhD Information Retrieval", institution: "University of Botswana", awarded_year: 2009 },
      { degree_title: "BSc Computer Science", institution: "University of Botswana", awarded_year: 2003 }
    ],
    employment_period: { start: ISODate("2010-01-15"), end: null },
    personal: {
      first_name: "Dr. Sarah",
      last_name: "Mphathi",
      date_of_birth: ISODate("1978-09-03"),
      gender: "F",
      address: { street: "19 Broadhurst", city: "Gaborone", postcode: "00267", country: "Botswana" },
      contact: { phone: "+267-77222222", email: "s.mphathi@uni.ac.bw" }
    },
    academic_rank: "Senior Lecturer",
    research_area: "Database Systems & Information Retrieval",
    office_location: "SA-202"
  },
  {
    _id: 23,
    type: "lecturer",
    staff_number: "STF1003",
    department_id: 2,
    hire_date: ISODate("2015-07-01"),
    salary: 68000,
    qualifications: [
      { degree_title: "PhD Information Systems", institution: "Wits University", awarded_year: 2014 }
    ],
    employment_period: { start: ISODate("2015-07-01"), end: null },
    personal: {
      first_name: "Dr. Kevin",
      last_name: "Banda",
      date_of_birth: ISODate("1982-12-20"),
      gender: "M",
      address: { street: "55 Extension 9", city: "Gaborone", postcode: "00267", country: "Botswana" },
      contact: { phone: "+267-77333333", email: "k.banda@uni.ac.bw" }
    },
    academic_rank: "Lecturer",
    research_area: "Enterprise Information Systems",
    office_location: "CB-115"
  },
  // Administrators 
  {
    _id: 24,
    type: "administrator",
    staff_number: "STF2001",
    department_id: 1,
    hire_date: ISODate("2012-03-01"),
    salary: 52000,
    qualifications: [
      { degree_title: "MBA Management", institution: "University of Botswana", awarded_year: 2011 }
    ],
    employment_period: { start: ISODate("2012-03-01"), end: null },
    personal: {
      first_name: "Mary",
      last_name: "Gabana",
      date_of_birth: ISODate("1985-05-25"),
      gender: "F",
      address: { street: "10 Government Enclave", city: "Gaborone", postcode: "00267", country: "Botswana" },
      contact: { phone: "+267-77444444", email: "m.gabana@uni.ac.bw" }
    },
    admin_role: "Head of Registry",
    manages_department: 1
  },
  {
    _id: 25,
    type: "administrator",
    staff_number: "STF2002",
    department_id: 2,
    hire_date: ISODate("2018-06-01"),
    salary: 49000,
    qualifications: [
      { degree_title: "PGDip Academic Administration", institution: "Wits University", awarded_year: 2017 }
    ],
    employment_period: { start: ISODate("2018-06-01"), end: null },
    personal: {
      first_name: "John",
      last_name: "Seretse",
      date_of_birth: ISODate("1980-08-14"),
      gender: "M",
      address: { street: "33 Commerce Park", city: "Gaborone", postcode: "00267", country: "Botswana" },
      contact: { phone: "+267-77555555", email: "j.seretse@uni.ac.bw" }
    },
    admin_role: "Departmental Secretary",
    manages_department: 2
  }
]);

// Updating department heads
db.departments.updateOne({ _id: 1 }, { $set: { head_of_dept: 21 } });
db.departments.updateOne({ _id: 2 }, { $set: { head_of_dept: 23 } });

// 5. INSERTING STUDENTS (they have some personal data for a more realistic data set)
db.students.insertMany([
  { _id: 1, student_number: "STU2021001", programme: "BSc Computer Science", level: 3,
    admission_date: ISODate("2021-09-01"), expected_graduation: ISODate("2024-06-30"), scholarship_amount: 2500,
    valid_period: { start: ISODate("2021-09-01"), end: ISODate("2024-06-30") },
    personal: { first_name: "Alice", last_name: "Mokoena", date_of_birth: ISODate("2001-03-15"), gender: "F",
                address: { street: "12 Jacaranda Ave", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-71234567", email: "alice.mokoena@uni.ac.bw" } } },
  { _id: 2, student_number: "STU2020002", programme: "BSc Information Systems", level: 3,
    admission_date: ISODate("2020-09-01"), expected_graduation: ISODate("2023-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2020-09-01"), end: ISODate("2023-06-30") },
    personal: { first_name: "Brian", last_name: "Sithole", date_of_birth: ISODate("2000-07-22"), gender: "M",
                address: { street: "45 Kgale Hill Rd", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-72345678", email: "b.sithole@uni.ac.bw" } } },
  { _id: 3, student_number: "STU2022003", programme: "BSc Computer Science", level: 2,
    admission_date: ISODate("2022-09-01"), expected_graduation: ISODate("2025-06-30"), scholarship_amount: 1500,
    valid_period: { start: ISODate("2022-09-01"), end: ISODate("2025-06-30") },
    personal: { first_name: "Clara", last_name: "Dlamini", date_of_birth: ISODate("2002-11-05"), gender: "F",
                address: { street: "8 Tlokweng Rd", city: "Gaborone", postcode: "00268", country: "Botswana" },
                contact: { phone: "+267-73456789", email: "c.dlamini@uni.ac.bw" } } },
  { _id: 4, student_number: "STU2019004", programme: "MSc Data Science", level: 7,
    admission_date: ISODate("2019-09-01"), expected_graduation: ISODate("2023-06-30"), scholarship_amount: 5000,
    valid_period: { start: ISODate("2019-09-01"), end: ISODate("2023-06-30") },
    personal: { first_name: "David", last_name: "Nkosi", date_of_birth: ISODate("1999-01-30"), gender: "M",
                address: { street: "22 Lobatse Rd", city: "Kanye", postcode: "00270", country: "Botswana" },
                contact: { phone: "+267-74567890", email: "d.nkosi@uni.ac.bw" } } },
  { _id: 5, student_number: "STU2023005", programme: "BSc Software Engineering", level: 1,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2023-09-01"), end: ISODate("2026-06-30") },
    personal: { first_name: "Esi", last_name: "Ofori", date_of_birth: ISODate("2003-06-18"), gender: "F",
                address: { street: "3 Station Rd", city: "Francistown", postcode: "00271", country: "Botswana" },
                contact: { phone: "+267-75678901", email: "e.ofori@uni.ac.bw" } } },
  { _id: 6, student_number: "STU2024030", programme: "BSc Computer Science", level: 1,
    admission_date: ISODate("2024-09-01"), expected_graduation: ISODate("2027-06-30"), scholarship_amount: 1200,
    valid_period: { start: ISODate("2024-09-01"), end: null },
    personal: { first_name: "Larona", last_name: "Dichabeng", date_of_birth: ISODate("2001-07-19"), gender: "F",
                address: { street: "15 Phase 2", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78123456", email: "larona.dichabeng@uni.ac.bw" } } },
  { _id: 7, student_number: "STU2024031", programme: "BSc Information Systems", level: 1,
    admission_date: ISODate("2024-09-01"), expected_graduation: ISODate("2027-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2024-09-01"), end: null },
    personal: { first_name: "Mohuammed", last_name: "Adnan", date_of_birth: ISODate("2002-02-11"), gender: "M",
                address: { street: "22 Broadhurst", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78234567", email: "mohuammed.adnan@uni.ac.bw" } } },
  { _id: 8, student_number: "STU2024032", programme: "BSc Software Engineering", level: 2,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 800,
    valid_period: { start: ISODate("2023-09-01"), end: null },
    personal: { first_name: "Ahmed", last_name: "Salaam", date_of_birth: ISODate("2000-11-30"), gender: "M",
                address: { street: "8 Village", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78345678", email: "ahmed.salaam@uni.ac.bw" } } },
  { _id: 9, student_number: "STU2024033", programme: "BSc Data Science", level: 1,
    admission_date: ISODate("2024-09-01"), expected_graduation: ISODate("2027-06-30"), scholarship_amount: 2000,
    valid_period: { start: ISODate("2024-09-01"), end: null },
    personal: { first_name: "Sesame", last_name: "Strawburt", date_of_birth: ISODate("2003-04-05"), gender: "F",
                address: { street: "42 Extension 5", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78456789", email: "sesame.strawburt@uni.ac.bw" } } },
  { _id: 10, student_number: "STU2024034", programme: "BSc Computer Science", level: 2,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2023-09-01"), end: null },
    personal: { first_name: "Warona", last_name: "Burner", date_of_birth: ISODate("2001-12-17"), gender: "M",
                address: { street: "3 Mogoditshane", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78567890", email: "warona.burner@uni.ac.bw" } } },
  { _id: 11, student_number: "STU2024035", programme: "BSc Information Systems", level: 3,
    admission_date: ISODate("2022-09-01"), expected_graduation: ISODate("2025-06-30"), scholarship_amount: 1500,
    valid_period: { start: ISODate("2022-09-01"), end: ISODate("2025-06-30") },
    personal: { first_name: "Kitso", last_name: "Magang", date_of_birth: ISODate("2002-09-23"), gender: "M",
                address: { street: "11 Phakalane", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78678901", email: "kitso.magang@uni.ac.bw" } } },
  { _id: 12, student_number: "STU2024036", programme: "BSc Software Engineering", level: 2,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 500,
    valid_period: { start: ISODate("2023-09-01"), end: null },
    personal: { first_name: "Ofile", last_name: "Lesotlho", date_of_birth: ISODate("2000-05-14"), gender: "F",
                address: { street: "27 Tlokweng", city: "Gaborone", postcode: "00268", country: "Botswana" },
                contact: { phone: "+267-78789012", email: "ofile.lesotlho@uni.ac.bw" } } },
  { _id: 13, student_number: "STU2024037", programme: "BSc Data Science", level: 1,
    admission_date: ISODate("2024-09-01"), expected_graduation: ISODate("2027-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2024-09-01"), end: null },
    personal: { first_name: "Tapiwa", last_name: "Yuji", date_of_birth: ISODate("2003-08-27"), gender: "M",
                address: { street: "9 Block 3", city: "Lobatse", postcode: "00270", country: "Botswana" },
                contact: { phone: "+267-78890123", email: "tapiwa.yuji@uni.ac.bw" } } },
  { _id: 14, student_number: "STU2024038", programme: "BSc Computer Science", level: 2,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 1300,
    valid_period: { start: ISODate("2023-09-01"), end: null },
    personal: { first_name: "Gojo", last_name: "Gernash", date_of_birth: ISODate("2002-01-13"), gender: "M",
                address: { street: "55 Gaborone West", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-78901234", email: "gojo.gernash@uni.ac.bw" } } },
  { _id: 15, student_number: "STU2024039", programme: "BSc Information Systems", level: 3,
    admission_date: ISODate("2022-09-01"), expected_graduation: ISODate("2025-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2022-09-01"), end: ISODate("2025-06-30") },
    personal: { first_name: "Saleem", last_name: "Jobs", date_of_birth: ISODate("2001-06-21"), gender: "M",
                address: { street: "14 Forest Hill", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-79012345", email: "saleem.jobs@uni.ac.bw" } } },
  { _id: 16, student_number: "STU2024040", programme: "BSc Software Engineering", level: 1,
    admission_date: ISODate("2024-09-01"), expected_graduation: ISODate("2027-06-30"), scholarship_amount: 2200,
    valid_period: { start: ISODate("2024-09-01"), end: null },
    personal: { first_name: "Eli", last_name: "Cinco", date_of_birth: ISODate("2000-10-09"), gender: "M",
                address: { street: "2 Riverwalk", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-79123456", email: "eli.cinco@uni.ac.bw" } } },
  { _id: 17, student_number: "STU2024041", programme: "BSc Data Science", level: 2,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2023-09-01"), end: null },
    personal: { first_name: "Thamaga", last_name: "Motswapong", date_of_birth: ISODate("2004-03-03"), gender: "M",
                address: { street: "19 Bontleng", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-79234567", email: "thamaga.motswapong@uni.ac.bw" } } },
  { _id: 18, student_number: "STU2024042", programme: "BSc Computer Science", level: 1,
    admission_date: ISODate("2024-09-01"), expected_graduation: ISODate("2027-06-30"), scholarship_amount: 750,
    valid_period: { start: ISODate("2024-09-01"), end: null },
    personal: { first_name: "Derrick", last_name: "Mudjana", date_of_birth: ISODate("2001-11-12"), gender: "M",
                address: { street: "31 Extension 10", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-79345678", email: "derrick.mudjana@uni.ac.bw" } } },
  { _id: 19, student_number: "STU2024043", programme: "BSc Information Systems", level: 2,
    admission_date: ISODate("2023-09-01"), expected_graduation: ISODate("2026-06-30"), scholarship_amount: 900,
    valid_period: { start: ISODate("2023-09-01"), end: null },
    personal: { first_name: "Thato", last_name: "Molefhi", date_of_birth: ISODate("2002-07-07"), gender: "F",
                address: { street: "7 Broadhurst", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-79456789", email: "thato.molefhi@uni.ac.bw" } } },
  { _id: 20, student_number: "STU2024044", programme: "BSc Software Engineering", level: 3,
    admission_date: ISODate("2022-09-01"), expected_graduation: ISODate("2025-06-30"), scholarship_amount: 0,
    valid_period: { start: ISODate("2022-09-01"), end: ISODate("2025-06-30") },
    personal: { first_name: "Isheanesu", last_name: "Nyangari", date_of_birth: ISODate("2001-09-18"), gender: "M",
                address: { street: "23 Old Naledi", city: "Gaborone", postcode: "00267", country: "Botswana" },
                contact: { phone: "+267-79567890", email: "isheanesu.nyangari@uni.ac.bw" } } }
]);

// 6. INSERTING COURSES
db.courses.insertMany([
  { _id: 1, course_code: "CS301", course_name: "Database Systems", credits: 20, level: 3,
    department_id: 1, lecturer_id: 22,
    offering_period: { start: ISODate("2023-09-01"), end: ISODate("2024-06-30") } },
  { _id: 2, course_code: "CS302", course_name: "Artificial Intelligence", credits: 20, level: 3,
    department_id: 1, lecturer_id: 21,
    offering_period: { start: ISODate("2023-09-01"), end: ISODate("2024-06-30") } },
  { _id: 3, course_code: "CS201", course_name: "Data Structures & Algorithms", credits: 20, level: 2,
    department_id: 1, lecturer_id: 22,
    offering_period: { start: ISODate("2023-09-01"), end: ISODate("2024-06-30") } },
  { _id: 4, course_code: "IS301", course_name: "Enterprise Systems", credits: 20, level: 3,
    department_id: 2, lecturer_id: 23,
    offering_period: { start: ISODate("2023-09-01"), end: ISODate("2024-06-30") } },
  { _id: 5, course_code: "IS401", course_name: "IT Project Management", credits: 20, level: 6,
    department_id: 2, lecturer_id: 23,
    offering_period: { start: ISODate("2023-09-01"), end: ISODate("2024-06-30") } },
  { _id: 6, course_code: "CS701", course_name: "Advanced Machine Learning", credits: 30, level: 7,
    department_id: 1, lecturer_id: 21,
    offering_period: { start: ISODate("2023-09-01"), end: ISODate("2024-06-30") } }
]);

// 7. INSERTING ENROLLMENTS
db.enrollments.insertMany([
  // Original 10 enrollments
  { student_id: 1, course_id: 1, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"),
    status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 35.5 }, { component: "Exam", weight: 60, score: 52 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 1, course_id: 2, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"),
    status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 38 }, { component: "Exam", weight: 60, score: 55 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 1, course_id: 4, enrolled_at: ISODate("2024-02-01"), completed_at: null,
    status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 30 }],
    enrollment_period: { start: ISODate("2024-02-01"), end: null } },
  { student_id: 2, course_id: 1, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"),
    status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 28 }, { component: "Exam", weight: 60, score: 40 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 2, course_id: 4, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"),
    status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 36 }, { component: "Exam", weight: 60, score: 50 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 3, course_id: 3, enrolled_at: ISODate("2023-09-01"), completed_at: null,
    status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 37 }, { component: "Exam", weight: 60, score: 48 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: null } },
  { student_id: 3, course_id: 1, enrolled_at: ISODate("2024-02-01"), completed_at: null,
    status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 34 }],
    enrollment_period: { start: ISODate("2024-02-01"), end: null } },
  { student_id: 4, course_id: 6, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-03-31"),
    status: "completed",
    grade_components: [{ component: "Thesis Proposal", weight: 30, score: 27 }, { component: "Written Exam", weight: 40, score: 36 }, { component: "Viva", weight: 30, score: 28 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-03-31") } },
  { student_id: 4, course_id: 5, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"),
    status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 38 }, { component: "Exam", weight: 60, score: 54 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 5, course_id: 3, enrolled_at: ISODate("2023-09-01"), completed_at: null,
    status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 20 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: null } },
  // Additional enrollments for students 6-20
  { student_id: 6, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 32 }, { component: "Exam", weight: 60, score: 48 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 7, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 36 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 9, course_id: 3, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"), status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 38 }, { component: "Exam", weight: 60, score: 56 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 13, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 30 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 16, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 34 }, { component: "Exam", weight: 60, score: 52 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 18, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 35 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 8, course_id: 3, enrolled_at: ISODate("2023-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 33 }, { component: "Exam", weight: 60, score: 51 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: null } },
  { student_id: 8, course_id: 1, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"), status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 37 }, { component: "Exam", weight: 60, score: 55 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 10, course_id: 2, enrolled_at: ISODate("2024-02-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 30 }],
    enrollment_period: { start: ISODate("2024-02-01"), end: null } },
  { student_id: 12, course_id: 4, enrolled_at: ISODate("2023-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 36 }, { component: "Exam", weight: 60, score: 54 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: null } },
  { student_id: 14, course_id: 1, enrolled_at: ISODate("2024-02-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 34 }],
    enrollment_period: { start: ISODate("2024-02-01"), end: null } },
  { student_id: 17, course_id: 2, enrolled_at: ISODate("2024-02-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 32 }, { component: "Exam", weight: 60, score: 50 }],
    enrollment_period: { start: ISODate("2024-02-01"), end: null } },
  { student_id: 19, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 38 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 11, course_id: 1, enrolled_at: ISODate("2024-02-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 35 }, { component: "Exam", weight: 60, score: 53 }],
    enrollment_period: { start: ISODate("2024-02-01"), end: null } },
  { student_id: 11, course_id: 4, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 33 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } },
  { student_id: 15, course_id: 2, enrolled_at: ISODate("2023-09-01"), completed_at: ISODate("2024-01-31"), status: "completed",
    grade_components: [{ component: "Coursework", weight: 40, score: 39 }, { component: "Exam", weight: 60, score: 57 }],
    enrollment_period: { start: ISODate("2023-09-01"), end: ISODate("2024-01-31") } },
  { student_id: 20, course_id: 3, enrolled_at: ISODate("2024-09-01"), completed_at: null, status: "active",
    grade_components: [{ component: "Coursework", weight: 40, score: 31 }, { component: "Exam", weight: 60, score: 49 }],
    enrollment_period: { start: ISODate("2024-09-01"), end: null } }
]);

// 8. QUERY 5a: Active enrollments with student, course, department, lecturer
print("\n--- QUERY 5a: Active Enrollments (Student, Course, Lecturer) ---");
db.enrollments.aggregate([
  { $match: { status: "active" } },
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "student" } },
  { $unwind: "$student" },
  { $lookup: { from: "courses", localField: "course_id", foreignField: "_id", as: "course" } },
  { $unwind: "$course" },
  { $lookup: { from: "departments", localField: "course.department_id", foreignField: "_id", as: "dept" } },
  { $unwind: { path: "$dept", preserveNullAndEmptyArrays: true } },
  { $lookup: { from: "staff", localField: "course.lecturer_id", foreignField: "_id", as: "lecturer" } },
  { $unwind: { path: "$lecturer", preserveNullAndEmptyArrays: true } },
  { $project: {
      student_name: { $concat: [ "$student.personal.first_name", " ", "$student.personal.last_name" ] },
      student_number: "$student.student_number",
      programme: "$student.programme",
      course_code: "$course.course_code",
      course_name: "$course.course_name",
      course_level: "$course.level",
      department: "$dept.dept_name",
      lecturer: { $ifNull: [ { $concat: [ "$lecturer.personal.first_name", " ", "$lecturer.personal.last_name" ] }, "Unassigned" ] },
      status: 1
    } },
  { $sort: { student_name: 1, course_code: 1 } }
]).forEach(printjson);

// 9. QUERY 5b: Staff directory (lecturers + administrators)
print("\n--- QUERY 5b: Staff Directory (Lecturers + Administrators) ---");
db.staff.aggregate([
  { $lookup: { from: "departments", localField: "department_id", foreignField: "_id", as: "dept" } },
  { $unwind: "$dept" },
  { $project: {
      staff_category: { $cond: [ { $eq: [ "$type", "lecturer" ] }, "Lecturer", "Administrator" ] },
      full_name: { $concat: [ "$personal.first_name", " ", "$personal.last_name" ] },
      role_or_rank: { $ifNull: [ "$academic_rank", "$admin_role" ] },
      department: "$dept.dept_name",
      email: "$personal.contact.email"
    } },
  { $sort: { staff_category: 1, full_name: 1 } }
]).forEach(printjson);

// 10. QUERY 5c: Unnest qualifications array
print("\n--- QUERY 5c: Staff Qualifications (unnested) ---");
db.staff.aggregate([
  { $lookup: { from: "departments", localField: "department_id", foreignField: "_id", as: "dept" } },
  { $unwind: "$dept" },
  { $unwind: { path: "$qualifications", preserveNullAndEmptyArrays: false } },
  { $project: {
      staff_name: { $concat: [ "$personal.first_name", " ", "$personal.last_name" ] },
      staff_type: "$type",
      position: { $ifNull: [ "$academic_rank", "$admin_role" ] },
      department: "$dept.dept_name",
      qualification: "$qualifications.degree_title",
      institution: "$qualifications.institution",
      year_awarded: "$qualifications.awarded_year"
    } },
  { $sort: { staff_name: 1, year_awarded: -1 } }
]).forEach(printjson);

// 11. QUERY 5d: Temporal enrollment metrics
print("\n--- QUERY 5d: Temporal Enrollment Metrics ---");
db.enrollments.aggregate([
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "student" } },
  { $unwind: "$student" },
  { $lookup: { from: "courses", localField: "course_id", foreignField: "_id", as: "course" } },
  { $unwind: "$course" },
  { $addFields: {
      duration_start: { $ifNull: [ "$enrollment_period.start", "$enrolled_at" ] },
      duration_end: { $ifNull: [ "$enrollment_period.end", new Date() ] },
      currently_active: { $cond: [ { $eq: [ "$status", "active" ] }, true, false ] },
      age_at_enrollment: {
        $floor: {
          $divide: [
            { $subtract: [ "$duration_start", "$student.personal.date_of_birth" ] },
            31556952000  // milliseconds in a year (365.25 days)
          ]
        }
      },
      months_since_enrollment: {
        $divide: [
          { $subtract: [ new Date(), "$duration_start" ] },
            2629746000  // milliseconds in a month (30.44 days)
        ]
      },
      enrolled_on_formatted: { $dateToString: { format: "%d %b %Y %H:%M", date: "$duration_start" } }
    } },
  { $project: {
      student_name: { $concat: [ "$student.personal.first_name", " ", "$student.personal.last_name" ] },
      course_name: "$course.course_name",
      status: 1,
      duration: { $concat: [ 
        { $toString: { $floor: { $divide: [ { $subtract: [ "$duration_end", "$duration_start" ] }, 2592000000 ] } } }, 
        " month(s) and ", 
        { $toString: { $floor: { $mod: [ { $divide: [ { $subtract: [ "$duration_end", "$duration_start" ] }, 86400000 ] }, 30 ] } } }, 
        " day(s)" 
      ] },
      currently_active: 1,
      age_at_enrollment: 1,
      months_since_enrollment: { $round: [ "$months_since_enrollment", 2 ] },
      enrolled_on: "$enrolled_on_formatted"
    } },
  { $sort: { enrolled_on: -1 } }
]).forEach(printjson);

// 12. QUERY 5e: OLAP report (group by department, programme, level)
print("\n--- QUERY 5e: OLAP Report (Department, Programme, Level) ---");
db.enrollments.aggregate([
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "student" } },
  { $unwind: "$student" },
  { $lookup: { from: "courses", localField: "course_id", foreignField: "_id", as: "course" } },
  { $unwind: "$course" },
  { $lookup: { from: "departments", localField: "course.department_id", foreignField: "_id", as: "dept" } },
  { $unwind: "$dept" },
  { $addFields: { avg_score: { $avg: "$grade_components.score" } } },
  { $group: {
      _id: {
        dept_name: "$dept.dept_name",
        programme: "$student.programme",
        level: "$student.level"
      },
      total_enrollments: { $sum: 1 },
      avg_component_score: { $avg: "$avg_score" }
    } },
  { $project: {
      department: "$_id.dept_name",
      programme: "$_id.programme",
      student_level: { $toString: "$_id.level" },
      total_enrollments: 1,
      avg_component_score: { $round: [ { $ifNull: [ "$avg_component_score", 0 ] }, 2 ] }
    } },
  { $sort: { department: 1, programme: 1, student_level: 1 } }
]).forEach(printjson);

// Another way of doing Query5 by show grand total (simulating ROLLUP)
print("\n--- QUERY 5e (Supplement): Grand Total ---");
db.enrollments.aggregate([
  { $lookup: { from: "students", localField: "student_id", foreignField: "_id", as: "student" } },
  { $unwind: "$student" },
  { $lookup: { from: "courses", localField: "course_id", foreignField: "_id", as: "course" } },
  { $unwind: "$course" },
  { $lookup: { from: "departments", localField: "course.department_id", foreignField: "_id", as: "dept" } },
  { $unwind: "$dept" },
  { $addFields: { avg_score: { $avg: "$grade_components.score" } } },
  { $group: { _id: null, total_enrollments: { $sum: 1 }, avg_component_score: { $avg: "$avg_score" } } },
  { $project: { department: "** ALL DEPARTMENTS **", programme: "** ALL PROGRAMMES **", student_level: "ALL", total_enrollments: 1, avg_component_score: { $round: [ "$avg_component_score", 2 ] } } }
]).forEach(printjson);

print("\n--- script completed.Thank you ---");