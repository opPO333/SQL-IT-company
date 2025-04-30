CREATE TABLE addresses (
	id SERIAL PRIMARY KEY,
	house VARCHAR(20) NOT NULL,
	street VARCHAR(50) NOT NULL,
	city VARCHAR(50) NOT NULL,
	country VARCHAR(50) NOT NULL,
	state VARCHAR(50),
	postal_code VARCHAR(20),

	UNIQUE(postal_code, city, street, house, state, country)
);


CREATE TABLE departments (
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) UNIQUE NOT NULL,
	--- ID of the 'leader' of department
	head_id INTEGER NOT NULL
);

CREATE TABLE projects (
	id SERIAL PRIMARY KEY,
	name VARCHAR(30) UNIQUE NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE,
	company VARCHAR(30) NOT NULL,
	
	CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE teams (
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) UNIQUE NOT NULL,
	--- Maybe add the time from -> to this team was exist
	
	project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL,
	lead_id INTEGER
);


CREATE TABLE employees (
	id SERIAL PRIMARY KEY,
	first_name VARCHAR(30) NOT NULL,
	last_name VARCHAR(30) NOT NULL,
	second_name VARCHAR(30),
	gender CHAR(1) NOT NULL,
	phone VARCHAR(20),
	email VARCHAR(100) UNIQUE,
	passport VARCHAR(20) UNIQUE,
	pesel CHAR(11) UNIQUE,
	address_id INTEGER REFERENCES addresses(id) ON DELETE RESTRICT,
	correspondence_address_id INTEGER REFERENCES addresses(id) ON DELETE RESTRICT,
	birth_date DATE,
	departament_id INTEGER NOT NULL,
	team_id INTEGER REFERENCES teams(id),
	

	CHECK(gender IN ('M', 'F')),
	CHECK(birth_date <= CURRENT_DATE),
	CHECK(phone IS NOT NULL OR email IS NOT NULL),
	CHECK(passport IS NOT NULL OR pesel IS NOT NULL)
);

ALTER TABLE departments
ADD CONSTRAINT departments_ref_key
FOREIGN KEY (head_id) REFERENCES employees(id) ON DELETE RESTRICT;

ALTER TABLE teams
ADD CONSTRAINT teams_ref_key
FOREIGN KEY (lead_id) REFERENCES employees(id) ON DELETE SET NULL;

ALTER TABLE employees
ADD CONSTRAINT employees_ref_key
FOREIGN KEY (departament_id) REFERENCES departments(id) ON DELETE RESTRICT;


CREATE TABLE employee_teams_history (
	id SERIAL PRIMARY KEY,
	employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
	team_id INTEGER REFERENCES teams(id) ON DELETE CASCADE NOT NULL,
	join_date DATE NOT NULL,
	leave_date DATE,
	
	CHECK (leave_date IS NULL OR join_date <= leave_date)
);


CREATE TABLE positions (
	position VARCHAR(30) PRIMARY KEY,
	salary NUMERIC(10, 2) NOT NULL

	CHECK(salary > 0),
	CHECK(position IN ('teamlead', 'ceo'))
);


CREATE TABLE employee_hours (
	id SERIAL PRIMARY KEY,
	employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
	date DATE NOT NULL,
	is_paid BOOLEAN DEFAULT FALSE
);


CREATE TABLE position_schedules (
	id SERIAL PRIMARY KEY,
	position VARCHAR(30) REFERENCES positions(position) ON DELETE CASCADE,
	day_of_weak INTEGER,
	start_time TIME NOT NULL,
	end_time TIME NOT NULL,
	
	CHECK (day_of_weak BETWEEN 1 AND 7)
);


CREATE TABLE schedule_exceptions (
	id SERIAL PRIMARY KEY,
	employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE NOT NULL,
	date DATE NOT NULL,
	type VARCHAR(30) NOT NULL,
	is_paid BOOLEAN NOT NULL,
	description VARCHAR(255),
	
	CHECK (type IN ('vacation', 'sick', 'day_off', 'absent', 'holiday'))
);


CREATE TABLE holidays (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) UNIQUE NOT NULL,
	date DATE NOT NULL,
	is_reccuring BOOLEAN DEFAULT TRUE
);


--Should be some 'manager' position that should approve such things
CREATE TABLE vacations (
	id SERIAL PRIMARY KEY,
	employee_id INTEGER REFERENCES employees(id) NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE NOT NULL,
	type VARCHAR(20) NOT NULL,
	status VARCHAR(20) DEFAULT 'requested' NOT NULL,
	approved_by INTEGER REFERENCES employees(id),
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	
	CHECK (type IN ('paid', 'unpaid', 'sick', 'parental')),
	CHECK (status IN ('requested', 'approved', 'rejected', 'canceled'))
);


CREATE TABLE employee_positions_history (
	id SERIAL PRIMARY KEY,
	employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
	position VARCHAR(30) REFERENCES positions(position) ON DELETE CASCADE,
	start_date DATE NOT NULL,
	end_date DATE,

	CHECK(end_date IS NULL OR start_date <= end_date)
);


CREATE TABLE tasks (
	id SERIAL PRIMARY KEY,
	title VARCHAR(40) NOT NULL UNIQUE,
	description VARCHAR(200),
	project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE NOT NULL,
	team_id INTEGER REFERENCES teams(id) ON DELETE SET NULL,
	status VARCHAR(30) DEFAULT 'backlog' NOT NULL,
	priority VARCHAR(30) NOT NULL,
	added_date DATE NOT NULL,
	solved_date DATE,
	
	CHECK (solved_date IS NULL OR added_date <= solved_date)
);


CREATE TABLE equipment (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	type VARCHAR(30) NOT NULL,
	serial_number VARCHAR(50) UNIQUE,
	status VARCHAR(30) DEFAULT 'in_stock' NOT NULL,
	assigned_to INTEGER REFERENCES employees(id) ON DELETE SET NULL
);
