CREATE TABLE countries
(
    name VARCHAR PRIMARY KEY
);

CREATE TABLE regions
(
    id           SERIAL PRIMARY KEY,
    country_name VARCHAR NOT NULL REFERENCES countries (name) ON DELETE RESTRICT,
    name         VARCHAR(100)
);

CREATE TABLE cities
(
    id        SERIAL PRIMARY KEY,
    region_id INTEGER      NOT NULL REFERENCES regions (id) ON DELETE RESTRICT,
    name      VARCHAR(100) NOT NULL
);

CREATE TABLE addresses
(
    id          SERIAL PRIMARY KEY,
    house       VARCHAR(20) NOT NULL,
    street      VARCHAR(50),
    city_id     INTEGER     NOT NULL REFERENCES cities (id),
    postal_code VARCHAR(20)
);
CREATE UNIQUE INDEX idx_addresses_unique ON addresses (
                                                       postal_code,
                                                       COALESCE(street, ''),
                                                       house,
                                                       city_id
    );

CREATE TABLE employees
(
    id                        SERIAL PRIMARY KEY,
    first_name                VARCHAR(30)                       NOT NULL,
    last_name                 VARCHAR(30)                       NOT NULL,
    second_name               VARCHAR(30),
    gender                    CHAR(1)                           NOT NULL,
    phone                     VARCHAR(20),
    email                     VARCHAR(100) UNIQUE,
    passport                  VARCHAR(20) UNIQUE,
    pesel                     CHAR(11) UNIQUE,
    address_id                INTEGER                           REFERENCES addresses (id) ON DELETE SET NULL,
    correspondence_address_id INTEGER REFERENCES addresses (id) NOT NULL ON DELETE RESTRICT,
    birth_date                DATE                              NOT NULL,

    CHECK (gender IN ('M', 'F')),
    CHECK (birth_date <= CURRENT_DATE AND CURRENT_DATE - INTERVAL '18 years' >= birth_date),
    CHECK (phone IS NOT NULL OR email IS NOT NULL),
    CHECK (passport IS NOT NULL OR pesel IS NOT NULL)
);

-- TODO: ADD trigger when update smth from this info we need add to this table row
CREATE TABLE employee_name_history
(
    employee_id INTEGER     NOT NULL REFERENCES employees (id) ON DELETE RESTRICT,
    first_name  VARCHAR(30) NOT NULL,
    second_name VARCHAR(30),
    last_name   VARCHAR(30) NOT NULL,
    start_ts    TIMESTAMP   NOT NULL,
    end_ts      TIMESTAMP,

    CHECK (end_ts IS NULL OR start_ts <= end_ts),
    PRIMARY KEY (employee_id, start_ts)
);

CREATE TABLE departments
(
    name       VARCHAR(50) NOT NULL,
    start_date DATE        NOT NULL,
    end_date   DATE,

    CHECK (end_date IS NULL OR start_date <= end_date),
    PRIMARY KEY (name, start_date)
);



CREATE TABLE head_departments_history
(
    head_id               INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    department_name       VARCHAR(50)                                          NOT NULL,
    department_start_date DATE                                                 NOT NULL,
    start_date            DATE                                                 NOT NULL,
    end_date              DATE,

    CHECK (end_date IS NULL OR start_date <= end_date),
    PRIMARY KEY (head_id, start_date),
    FOREIGN KEY (department_name, department_start_date) REFERENCES departments (name, start_date)
        ON DELETE RESTRICT
);

CREATE TABLE employee_departments_history
(
    employee_id           INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    department_name       VARCHAR(50)                                          NOT NULL,
    department_start_date DATE                                                 NOT NULL,
    start_date            DATE                                                 NOT NULL,
    end_date              DATE,

    CHECK (end_date IS NULL OR start_date <= end_date),
    PRIMARY KEY (employee_id, start_date),
    FOREIGN KEY (department_name, department_start_date) REFERENCES departments (name, start_date)
        ON DELETE RESTRICT
);


CREATE TABLE projects
(
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(50) UNIQUE NOT NULL,
    description VARCHAR,
    start_date  DATE               NOT NULL,
    end_date    DATE,
    company     VARCHAR(30)        NOT NULL,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE teams
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(50) UNIQUE NOT NULL,
    start_date DATE               NOT NULL,
    end_date   DATE,
    project_id INTEGER            REFERENCES projects (id) ON DELETE SET NULL,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE employee_teams_history
(
    employee_id INTEGER REFERENCES employees (id) ON DELETE CASCADE NOT NULL,
    team_id     INTEGER REFERENCES teams (id) ON DELETE CASCADE     NOT NULL,
    join_ts     TIMESTAMP                                           NOT NULL,
    leave_ts    TIMESTAMP,

    CHECK (leave_ts IS NULL OR join_ts <= leave_ts),
    PRIMARY KEY (employee_id, join_ts)
);

CREATE TABLE positions
(
    position        VARCHAR(30) PRIMARY KEY,
    salary_per_hour NUMERIC(10, 2) NOT NULL,

    CHECK (salary_per_hour >= 0)
);

CREATE TABLE employee_schedule
(
    employee_id INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    weekday     INTEGER                                              NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    start_time  TIME                                                 NOT NULL,
    end_time    TIME                                                 NOT NULL,

    PRIMARY KEY (employee_id, weekday, start_time)
)

CREATE TABLE schedule_exceptions
(
    employee_id INTEGER REFERENCES employees (id) ON DELETE RESTRICT                      NOT NULL,
    date        DATE                                                                      NOT NULL,
    start_time  TIME                                                                      NOT NULL,
    end_time    TIME                                                                      NOT NULL,
    type        VARCHAR(30) REFERENCES schedule_exception_types (type) ON DELETE RESTRICT NOT NULL,
    description VARCHAR(255),

    PRIMARY KEY (employee_id, date, start_time)
);

CREATE TABLE schedule_exception_types
(
    type    VARCHAR(30) PRIMARY KEY NOT NULL,
    is_paid BOOLEAN                 NOT NULL,

    --Always in the lowercase
    CHECK (type = LOWER(type))
)

--Should be some 'mnger' position that should approve such things
CREATE TABLE vacations
(
    id          SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees (id) NOT NULL,
    start_date  DATE                              NOT NULL,
    end_date    DATE                              NOT NULL,
    type        VARCHAR(20)                       NOT NULL,
    status      VARCHAR(20) DEFAULT 'requested'   NOT NULL,
    approved_by INTEGER REFERENCES employees (id),
    created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,

    CHECK (type IN ('paid', 'unpaid', 'sick', 'parental')),
    CHECK (status IN ('requested', 'approved', 'rejected', 'canceled'))
);

CREATE TABLE employee_positions_history
(
    id          SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees (id) ON DELETE CASCADE,
    position    VARCHAR(30) REFERENCES positions (position) ON DELETE CASCADE,
    start_date  DATE NOT NULL,
    end_date    DATE,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE tasks
(
    id          SERIAL PRIMARY KEY,
    title       VARCHAR(40)                                        NOT NULL UNIQUE,
    description VARCHAR(200),
    project_id  INTEGER REFERENCES projects (id) ON DELETE CASCADE NOT NULL,
    team_id     INTEGER                                            REFERENCES teams (id) ON DELETE SET NULL,
    status      VARCHAR(30) DEFAULT 'backlog'                      NOT NULL,
    priority    INTEGER                                            NOT NULL,
    added_date  DATE                                               NOT NULL,
    solved_date DATE,

    CHECK (solved_date IS NULL OR added_date <= solved_date)
);

CREATE TYPE equipment_type AS ENUM (
    'laptop',
    'monitor',
    'phone',
    'router',
    'tablet'
    );

CREATE TYPE equipment_status AS ENUM (
    'in_stock',
    'assigned',
    'broken',
    'under_repair'
    );

CREATE TABLE equipment
(
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100)   NOT NULL,
    type          equipment_type NOT NULL,
    serial_number VARCHAR(50) UNIQUE,
    price         INTEGER
);

CREATE TABLE equipment_status_history
(
    equipment_id INTEGER REFERENCES equipment (id)   NOT NULL,
    status       equipment_status DEFAULT 'in_stock' NOT NULL,
    start_date   DATE                                NOT NULL,
    end_date     DATE,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE employee_equipment_history
(
    employee_id  INTEGER REFERENCES employees (id) NOT NULL,
    equipment_id INTEGER REFERENCES equipment (id) NOT NULL,
    start_date   DATE                              NOT NULL,
    end_date     DATE,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

  CREATE OR REPLACE VIEW employees_view AS
  SELECT
    e.id,
    e.first_name,
    e.last_name,
    e.pesel,
    edh.department_name,
    edh.department_start_date,
    eth.team_id
  FROM employees e
  JOIN employee_departments_history edh
    ON e.id = edh.employee_id
   AND edh.end_date IS NULL
  JOIN employee_teams_history eth on e.id = eth.employee_id;

CREATE OR REPLACE VIEW departments_view AS
SELECT d.*, concat(e.first_name, ' ', e.last_name) as head_name FROM departments d
LEFT JOIN head_departments_history hdh
    ON d.name = hdh.department_name AND d.start_date = hdh.department_start_date
LEFT JOIN employees e on hdh.head_id = e.id
WHERE d.end_date IS NULL;

CREATE OR REPLACE VIEW teams_view AS
    SELECT t.id, t.name, t.start_date, p.title as project_title
    FROM teams t LEFT JOIN projects p on p.id = t.project_id
    WHERE t.end_date IS NULL;


create or replace function pesel_check() returns trigger as
$$
declare
    sum     integer := 0;
    weights integer[];
begin
    weights := array [1, 3, 1, 9, 7, 3, 1, 9, 7, 3, 1];

    if char_length(new.pesel) != 11 then
        raise exception 'Wrong PESEL';
    end if;

    for i in 1..11
        loop
            if substring(new.pesel, i, 1) < '0' or substring(new.pesel, i, 1) > '9' then
                raise exception 'Wrong PESEL';
            end if;
        end loop;

    for i in 1..11
        loop
            sum = sum + weights[12 - i] * substring(new.pesel, i, 1)::integer;
        end loop;

    if sum % 10 != 0 then
        raise exception 'Wrong PESEL';
    end if;

    return new;
end;
$$ language plpgsql;

create trigger pesel_check
    before insert or update
    on employees
    for each row
execute function pesel_check();

-- Countries
INSERT INTO countries (name) VALUES
('Poland'),
('Germany'),
('United States');

-- Regions
INSERT INTO regions (country_name, name) VALUES
('Poland', 'Mazowieckie'),
('Poland', 'Malopolskie'),
('Germany', 'Bavaria'),
('United States', 'California');

-- Cities
INSERT INTO cities (region_id, name) VALUES
(1, 'Warsaw'),
(1, 'Radom'),
(2, 'Krakow'),
(3, 'Munich'),
(4, 'San Francisco');

-- Addresses
INSERT INTO addresses (house, street, city_id, postal_code) VALUES
('10A', 'Main Street', 1, '00-001'),
('5B', 'Second Street', 1, '00-002'),
('15', 'Old Town', 3, '30-001'),
('20', 'New Town', 3, '30-002'),
('100', 'Tech Street', 5, '94105');

-- Employees (with valid PESEL/passport and birth dates)
INSERT INTO employees
(first_name, last_name, second_name, gender, phone, email, passport, pesel, address_id, correspondence_address_id, birth_date) VALUES
('John', 'Smith', NULL, 'M', '+48123456789', 'john.smith@example.com', 'AB123456', '81071724424', 1, 1, '1990-01-01'),
('Anna', 'Nowak', 'Maria', 'F', '+48987654321', 'anna.nowak@example.com', 'CD789012', '94082186996', 3, 3, '1992-07-13'),
('Robert', 'Johnson', NULL, 'M', '+48555111222', 'robert.j@example.com', 'EF345678', '53112557616', 2, 2, '1985-05-05'),
('Eva', 'Brown', 'Sophie', 'F', '+48111222333', 'eva.b@example.com', NULL, '64110895776', 4, 4, '1998-02-02'),
('Michael', 'Taylor', 'James', 'M', '+14155551234', 'm.taylor@example.com', 'US987654', NULL, 5, 5, '1988-08-08');

-- Departments
INSERT INTO departments (name, start_date) VALUES
('IT', '2020-01-01'),
('HR', '2020-01-01'),
('Finance', '2021-03-15');

-- Head Departments History
INSERT INTO head_departments_history
(head_id, department_name, department_start_date, start_date) VALUES
(1, 'IT', '2020-01-01', '2020-01-01'),
(4, 'HR', '2020-01-01', '2021-06-01');

-- Employee Departments History
INSERT INTO employee_departments_history
(employee_id, department_name, department_start_date, start_date) VALUES
(1, 'IT', '2020-01-01', '2020-01-01'),
(2, 'HR', '2020-01-01', '2020-02-01'),
(3, 'IT', '2020-01-01', '2020-03-01'),
(4, 'HR', '2020-01-01', '2021-06-01'),
(5, 'Finance', '2021-03-15', '2022-01-10');

-- Projects
INSERT INTO projects
(title, description, start_date, end_date, company) VALUES
('Project Alpha', 'Internal system upgrade', '2023-01-01', NULL, 'Tech Solutions'),
('Project Beta', 'Client portal development', '2023-02-15', '2023-12-31', 'Global Inc'),
('Project Gamma', 'Payment system', '2023-03-10', NULL, 'Bank Corp');

-- Teams
INSERT INTO teams
(name, start_date, project_id) VALUES
('Dev Team A', '2023-01-01', 1),
('UX Team', '2023-02-20', 2),
('Finance Team', '2023-03-15', 3);

-- Employee Teams History
INSERT INTO employee_teams_history
(employee_id, team_id, join_ts) VALUES
(1, 1, '2023-01-01 09:00:00'),
(3, 1, '2023-01-15 10:00:00'),
(2, 2, '2023-02-20 11:00:00'),
(5, 3, '2023-03-20 08:30:00');

-- Positions
INSERT INTO positions (position, salary_per_hour) VALUES
('Senior Developer', 150.00),
('HR Specialist', 100.00),
('Finance Manager', 200.00),
('Junior Developer', 80.00);

-- Employee Positions History
INSERT INTO employee_positions_history
(employee_id, position, start_date) VALUES
(1, 'Senior Developer', '2020-01-01'),
(2, 'HR Specialist', '2020-02-01'),
(3, 'Junior Developer', '2020-03-01'),
(4, 'HR Specialist', '2021-06-01'),
(5, 'Finance Manager', '2022-01-10');

-- Tasks
INSERT INTO tasks
(title, description, project_id, team_id, status, priority, added_date) VALUES
('Implement auth', 'OAuth2 implementation', 1, 1, 'in progress', 1, '2023-01-10'),
('Design dashboard', 'User dashboard wireframes', 2, 2, 'backlog', 2, '2023-03-01'),
('Payment gateway', 'Integrate with Stripe API', 3, 3, 'in progress', 1, '2023-04-01');

-- Equipment
INSERT INTO equipment
(name, type, serial_number, price) VALUES
('MacBook Pro 16"', 'laptop', 'MPB16-12345', 3500),
('Dell UltraSharp 27"', 'monitor', 'DELL-U2719D', 700),
('iPhone 14 Pro', 'phone', 'IP14P-A1B2C3', 1200);

-- Equipment Status History
INSERT INTO equipment_status_history
(equipment_id, status, start_date) VALUES
(1, 'assigned', '2023-01-15'),
(2, 'assigned', '2023-02-01'),
(3, 'in_stock', '2023-03-10');

-- Employee Equipment History
INSERT INTO employee_equipment_history
(employee_id, equipment_id, start_date) VALUES
(1, 1, '2023-01-15'),
(1, 2, '2023-02-01');

-- Vacations
INSERT INTO vacations
(employee_id, start_date, end_date, type, status, approved_by) VALUES
(1, '2023-07-01', '2023-07-14', 'paid', 'approved', 4),
(2, '2023-08-01', '2023-08-07', 'paid', 'requested', NULL);

-- Schedule Exceptions
INSERT INTO schedule_exceptions
(employee_id, date, type, is_paid, description) VALUES
(3, '2023-05-01', 'holiday', true, 'Labor Day'),
(5, '2023-12-25', 'holiday', true, 'Christmas');