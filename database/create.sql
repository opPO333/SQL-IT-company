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

	CHECK(gender IN ('M', 'F')),
	CHECK(birth_date <= CURRENT_DATE),
	CHECK(phone IS NOT NULL OR email IS NOT NULL),
	CHECK(passport IS NOT NULL OR pesel IS NOT NULL)
);


CREATE TABLE positions (
	position VARCHAR(30) PRIMARY KEY,
	salary INTEGER NOT NULL,

	CHECK(salary > 0),
	CHECK(position IN ('teamlead', 'ceo'))
);





CREATE TABLE positions_history (
	id SERIAL PRIMARY KEY,
	employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
	position VARCHAR(30) REFERENCES positions(position) ON DELETE CASCADE,
	start_date DATE NOT NULL,
	end_date DATE,

	CHECK(end_date IS NULL OR start_date <= end_date)
);
















