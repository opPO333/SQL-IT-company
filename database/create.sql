CREATE TABLE countries
(
    name VARCHAR(100) PRIMARY KEY
);

CREATE TABLE regions
(
    id           SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL REFERENCES countries (name) ON DELETE RESTRICT,
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
    city_id     INTEGER     NOT NULL REFERENCES cities (id) ON DELETE RESTRICT,
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
    first_name                VARCHAR(30)                                          NOT NULL,
    last_name                 VARCHAR(30)                                          NOT NULL,
    second_name               VARCHAR(30),
    gender                    CHAR(1)                                              NOT NULL,
    phone                     VARCHAR(20),
    email                     VARCHAR(100) UNIQUE,
    passport                  VARCHAR(20) UNIQUE,
    pesel                     CHAR(11) UNIQUE,
    address_id                INTEGER                                              REFERENCES addresses (id) ON DELETE SET NULL,
    correspondence_address_id INTEGER REFERENCES addresses (id) ON DELETE RESTRICT NOT NULL,
    birth_date                DATE                                                 NOT NULL,

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
    end_ts      TIMESTAMP DEFAULT NULL,

    CHECK (end_ts IS NULL OR start_ts <= end_ts),
    PRIMARY KEY (employee_id, start_ts)
);

CREATE TABLE departments
(
    name       VARCHAR(50) NOT NULL,
    start_date DATE        NOT NULL,
    end_date   DATE DEFAULT NULL,

    CHECK (end_date IS NULL OR start_date <= end_date),
    PRIMARY KEY (name, start_date)
);

CREATE TABLE head_departments_history
(
    head_id               INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    department_name       VARCHAR(50)                                          NOT NULL,
    department_start_date DATE                                                 NOT NULL,
    start_date            DATE                                                 NOT NULL,
    end_date              DATE DEFAULT NULL,

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
    end_date              DATE DEFAULT NULL,

    CHECK (end_date IS NULL OR start_date <= end_date),
    PRIMARY KEY (employee_id, start_date),
    FOREIGN KEY (department_name, department_start_date) REFERENCES departments (name, start_date)
        ON DELETE RESTRICT
);

CREATE TABLE projects
(
    title       VARCHAR(50) PRIMARY KEY,
    description VARCHAR,
    start_date  DATE        NOT NULL,
    end_date    DATE DEFAULT NULL,
    company     VARCHAR(50) NOT NULL,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE teams
(
    id            SERIAL PRIMARY KEY,
    start_date    DATE NOT NULL,
    end_date      DATE DEFAULT NULL,
    project_title VARCHAR(50) REFERENCES projects (title) ON DELETE RESTRICT,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE employee_teams_history
(
    employee_id INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    team_id     INTEGER REFERENCES teams (id) ON DELETE RESTRICT     NOT NULL,
    join_ts     TIMESTAMP                                            NOT NULL,
    leave_ts    TIMESTAMP DEFAULT NULL,

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
);

CREATE TABLE schedule_exception_types
(
    type    VARCHAR(30) PRIMARY KEY NOT NULL,
    is_paid BOOLEAN                 NOT NULL,

    --Always in the lowercase
    CHECK (type = LOWER(type))
);

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

--Should be some 'mnger' position that should approve such things
CREATE TABLE vacations
(
    id          SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees (id) NOT NULL,
    start_date  DATE                              NOT NULL,
    end_date    DATE                              NOT NULL,
    type        VARCHAR(20)                       NOT NULL,
    status      VARCHAR(20) DEFAULT 'requested'   NOT NULL,
    approved_by INTEGER REFERENCES employees (id) ON DELETE RESTRICT,
    created_at  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,

    CHECK (type IN ('paid', 'unpaid', 'sick', 'parental')),
    CHECK (status IN ('requested', 'approved', 'rejected', 'canceled'))
);

CREATE TABLE employee_positions_history
(
    employee_id INTEGER REFERENCES employees (id) ON DELETE RESTRICT           NOT NULL,
    position    VARCHAR(30) REFERENCES positions (position) ON DELETE RESTRICT NOT NULL,
    start_date  DATE                                                           NOT NULL,
    end_date    DATE DEFAULT NULL,

    CHECK (end_date IS NULL OR start_date <= end_date),
    PRIMARY KEY (employee_id, start_date)
);

CREATE TABLE tasks
(
    id            SERIAL PRIMARY KEY,
    title         VARCHAR(40)                                                NOT NULL UNIQUE,
    description   VARCHAR(200),
    project_title VARCHAR(50) REFERENCES projects (title) ON DELETE RESTRICT NOT NULL,
    team_id       INTEGER                                                    REFERENCES teams (id) ON DELETE SET NULL,
    status        VARCHAR(30) DEFAULT 'backlog'                              NOT NULL,
    priority      INTEGER                                                    NOT NULL,
    added_date    DATE                                                       NOT NULL,
    solved_date   DATE,

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
    equipment_id INTEGER REFERENCES equipment (id) ON DELETE RESTRICT NOT NULL,
    status       equipment_status DEFAULT 'in_stock'                  NOT NULL,
    start_date   DATE                                                 NOT NULL,
    end_date     DATE DEFAULT NULL,

    CHECK (end_date IS NULL OR start_date <= end_date)
);

CREATE TABLE employee_equipment_history
(
    employee_id  INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    equipment_id INTEGER REFERENCES equipment (id) ON DELETE RESTRICT NOT NULL,
    start_date   DATE                                                 NOT NULL,
    end_date     DATE DEFAULT NULL,

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
    yy      integer;
    mm      integer;
    dd      integer;
    century integer;
    birth   date;
    gender  char(1);
begin
    if new.pesel is null then
        return new;
    end if;

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

    if substring(new.pesel, 10, 1)::int % 2 = 0 then
        gender := 'F';
    else
        gender := 'M';
    end if;

    if gender != new.gender then
        raise exception 'Gender does not match PESEL';
    end if;

    yy := substring(new.pesel from 1 for 2)::int;
    mm := substring(new.pesel from 3 for 2)::int;
    dd := substring(new.pesel from 5 for 2)::int;

    if mm between 1 and 12 then
        century := 1900;
    elsif mm between 21 and 32 then
        century := 2000;
        mm := mm - 20;
    elsif mm between 41 and 52 then
        century := 2100;
        mm := mm - 40;
    elsif mm between 61 and 72 then
        century := 2200;
        mm := mm - 60;
    elsif mm between 81 and 92 then
        century := 1800;
        mm := mm - 80;
    else
        raise exception 'Wrong PESEL: invalid month encoding';
    end if;

    birth := make_date(century + yy, mm, dd);

    if birth != new.birth_date then
        raise exception 'Birth date does not match PESEL';
    end if;

    return new;
end;
$$ language plpgsql;

create trigger pesel_check
    before insert or update
    on employees
    for each row
execute function pesel_check();



  CREATE VIEW employees_view AS
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

CREATE VIEW departments_view AS
SELECT d.*, concat(e.first_name, ' ', e.last_name) as head_name FROM departments d
LEFT JOIN head_departments_history hdh
    ON d.name = hdh.department_name AND d.start_date = hdh.department_start_date
LEFT JOIN employees e on hdh.head_id = e.id
WHERE d.end_date IS NULL;

CREATE VIEW teams_view AS
    SELECT t.id, t.start_date, p.title as project_title
    FROM teams t LEFT JOIN projects p on t.project_title = p.title
    WHERE t.end_date IS NULL;



/*
BEGIN;
INSERT INTO addresses (house, street, city, country, state, postal_code)
VALUES ('299', 'Lakeview Drive', 'Munich', 'Canada', 'Quebec', 'P6PYAR'),
       ('190', 'Cedar Lane', 'Chicago', 'USA', 'Illinois', '73791'),
       ('152Y', 'Tenth Avenue', 'Chicago', 'Australia', 'New South Wales', 'CW4U3U'),
       ('96G', '42nd Street', 'Tokyo', 'USA', 'Indiana', '25842'),
       ('77', '100th Avenue', 'Madrid', 'USA', 'Alaska', '73834'),
       ('178', 'Meadow Lane', 'San Diego', 'Germany', 'Bavaria', '95113'),
       ('253Q', 'Lakeview Drive', 'San Diego', 'Canada', 'Newfoundland', 'I6GOTS'),
       ('80', 'Mountain Road', 'Seoul', 'Australia', 'South Australia', 'YSBIK5'),
       ('232R', 'Southwest Lane', 'Vienna', 'Germany', 'Brandenburg', '36794'),
       ('175', 'Business Park Drive', 'Birmingham', 'USA', 'Kansas', '79078'),
       ('268', 'Corporate Boulevard', 'Mexico City', 'Australia', 'South Australia', 'DNISZE'),
       ('290', 'Industrial Avenue', 'Bangkok', 'Australia', 'Victoria', 'ZYCBQO'),
       ('189Y', 'Main Street', 'Tokyo', 'Germany', 'North Rhine-Westphalia', '40784'),
       ('218', 'Riverside Drive', 'Prague', 'Canada', 'Quebec', 'ONOTGI'),
       ('296F', 'East Road', 'Madrid', 'USA', 'Maryland', '92021'),
       ('75Z', 'Park Avenue', 'Barcelona', 'Australia', 'Queensland', 'MTVR2E'),
       ('190', 'First Street', 'Hong Kong', 'USA', 'Arizona', '22326'),
       ('247', 'Business Park Drive', 'Ottawa', 'USA', 'Kentucky', '87463'),
       ('281X', 'Technology Way', 'Amsterdam', 'USA', 'Alaska', '18767'),
       ('141', 'North Street', 'Madrid', 'Canada', 'Ontario', 'OVALTR'),
       ('108', 'Third Street', 'Birmingham', 'Germany', 'Bavaria', '85407'),
       ('87', 'Forest Drive', 'Ottawa', 'UK', 'Greater London', 'G6K51W'),
       ('248', 'Maple Road', 'Ottawa', 'Canada', 'Manitoba', '1BO5UH'),
       ('242', 'Meadow Lane', 'Seoul', 'Germany', 'Lower Saxony', '55152'),
       ('79', 'Southwest Lane', 'Chicago', 'Canada', 'Newfoundland', '62FU24'),
       ('216', 'North Street', 'Vancouver', 'Germany', 'Bremen', '26869'),
       ('223', 'Second Avenue', 'Cape Town', 'Canada', 'Manitoba', '3R97O6'),
       ('106', 'Riverside Drive', 'New York', 'Canada', 'Quebec', 'R130FP'),
       ('157', 'Second Avenue', 'Dubai', 'USA', 'Alabama', '50963'),
       ('286', 'Pine Boulevard', 'Munich', 'UK', 'North West', '01QGA7'),
       ('147', 'Main Street', 'Munich', 'Canada', 'Quebec', '4YHLIW'),
       ('42', 'Fifth Street', 'Cape Town', 'USA', 'Florida', '70621'),
       ('105', 'Commerce Road', 'Montreal', 'Canada', 'Alberta', 'EVQ0MQ'),
       ('286', 'Enterprise Street', 'Montreal', 'USA', 'Arkansas', '83823'),
       ('173', 'South Avenue', 'Rome', 'USA', 'Arkansas', '80387'),
       ('131', 'Business Park Drive', 'Amsterdam', 'UK', 'Wales', '7CYN6T'),
       ('240', '100th Avenue', 'Montreal', 'Germany', 'North Rhine-Westphalia', '95856'),
       ('113', 'Tenth Avenue', 'Rome', 'Germany', 'Bavaria', '80669'),
       ('223', 'High Street', 'Jakarta', 'Australia', 'Queensland', '9RI9PK'),
       ('243', 'Technology Way', 'Paris', 'Germany', 'Berlin', '37938'),
       ('96', 'South Avenue', 'Munich', 'Germany', 'Bavaria', '55874'),
       ('219', 'Church Street', 'San Diego', 'Germany', 'Bremen', '61899'),
       ('201', 'Tenth Avenue', 'Ottawa', 'USA', 'Indiana', '24550'),
       ('51G', 'Church Street', 'Berlin', 'Australia', 'Queensland', 'F5EDJ8'),
       ('228', '100th Avenue', 'Rio de Janeiro', 'Canada', 'Alberta', 'TW9FYL'),
       ('152', 'Market Street', 'Munich', 'Canada', 'Nova Scotia', '5YNYUO'),
       ('58', 'First Street', 'Mexico City', 'UK', 'Wales', 'FEW6FN'),
       ('123', 'Meadow Lane', 'Hong Kong', 'USA', 'Arkansas', '43912'),
       ('279', 'West Boulevard', 'Kuala Lumpur', 'Germany', 'Berlin', '67769'),
       ('286', 'Main Street', 'Cape Town', 'Australia', 'Queensland', '2EC1W8'),
       ('117', 'Riverside Drive', 'Toronto', 'UK', 'North West', '39SOWW'),
       ('156J', 'Oak Avenue', 'Miami', 'Germany', 'Brandenburg', '55940'),
       ('276', 'Enterprise Street', 'Amsterdam', 'Australia', 'Western Australia', '5EE59A'),
       ('46', 'Second Avenue', 'Seoul', 'USA', 'Alaska', '81537'),
       ('30', 'Meadow Lane', 'Seoul', 'Australia', 'Western Australia', 'H867F9'),
       ('63', 'Southwest Lane', 'Jakarta', 'Canada', 'Newfoundland', 'NRQQ09'),
       ('293Y', 'Northeast Drive', 'Brussels', 'Australia', 'Queensland', 'Y669DO'),
       ('129N', 'North Street', 'Amsterdam', 'USA', 'Arizona', '97752'),
       ('125', 'Technology Way', 'Sydney', 'Canada', 'New Brunswick', '97EKZN'),
       ('183', 'Valley View Road', 'Vancouver', 'USA', 'Georgia', '46302'),
       ('158U', 'Second Avenue', 'Seoul', 'USA', 'Arizona', '99624'),
       ('203W', 'Industrial Avenue', 'Tokyo', 'Germany', 'Bavaria', '96547'),
       ('237D', 'Second Avenue', 'Sydney', 'UK', 'Greater London', 'OFC6FQ'),
       ('40', 'Meadow Lane', 'Sydney', 'Canada', 'New Brunswick', 'W5ABGY'),
       ('254', 'Technology Way', 'Seoul', 'Australia', 'Queensland', 'QUX7TL'),
       ('28', 'Lakeview Drive', 'Tokyo', 'Canada', 'Ontario', '7YTTE7'),
       ('153', 'Third Street', 'Seoul', 'Germany', 'Bremen', '41037'),
       ('141', 'Valley View Road', 'Vancouver', 'Canada', 'Ontario', 'EMQ4NK'),
       ('206', '42nd Street', 'Dubai', 'Germany', 'Hamburg', '39522'),
       ('110', 'Market Street', 'Osaka', 'USA', 'Alaska', '77237'),
       ('57', 'Valley View Road', 'Dallas', 'Australia', 'Queensland', 'EEIA1C'),
       ('51', 'Elm Street', 'Chicago', 'UK', 'Scotland', 'XC9I4B'),
       ('175', 'Corporate Boulevard', 'Vancouver', 'UK', 'England', 'GMKD18'),
       ('59', 'First Street', 'Berlin', 'Australia', 'South Australia', 'RUM4WD'),
       ('227', 'Third Street', 'Chicago', 'Canada', 'Newfoundland', 'LV0RCD'),
       ('117O', 'Mountain Road', 'Singapore', 'Australia', 'Victoria', 'MN52HG'),
       ('139F', 'Commerce Road', 'Ottawa', 'UK', 'Scotland', '8YKB3Q'),
       ('77', 'Technology Way', 'Melbourne', 'UK', 'Scotland', 'CVXV3E'),
       ('236', '100th Avenue', 'Miami', 'USA', 'Hawaii', '70200'),
       ('113', 'Fifth Street', 'Jakarta', 'Germany', 'Berlin', '71784'),
       ('30', 'Business Park Drive', 'Munich', 'Australia', 'Western Australia', 'D9V97R'),
       ('265N', 'Commerce Road', 'Manchester', 'Australia', 'New South Wales', 'KXV7OK'),
       ('137T', 'East Road', 'Philadelphia', 'Canada', 'New Brunswick', 'OC502C'),
       ('280', 'Industrial Avenue', 'Madrid', 'Canada', 'Ontario', 'IR1I0A'),
       ('277', 'South Avenue', 'Paris', 'Germany', 'Bremen', '69163'),
       ('173H', 'Technology Way', 'Lyon', 'Canada', 'Quebec', 'D3IH0E'),
       ('91V', 'Pine Boulevard', 'Brussels', 'Germany', 'Bremen', '71813'),
       ('245M', 'Southwest Lane', 'Tokyo', 'Canada', 'British Columbia', 'CXFZHY'),
       ('144', 'Technology Way', 'Madrid', 'Canada', 'Quebec', '7IGT2K'),
       ('210', 'West Boulevard', 'Brussels', 'USA', 'Kansas', '83295'),
       ('211', 'Second Avenue', 'Toronto', 'Canada', 'British Columbia', 'I4V3US'),
       ('233S', 'Industrial Avenue', 'Montreal', 'UK', 'Greater London', 'N3HEIN'),
       ('243C', 'Business Park Drive', 'Johannesburg', 'UK', 'Wales', '4ZK0LN'),
       ('293E', 'Corporate Boulevard', 'Tokyo', 'UK', 'Wales', '1KP98I'),
       ('275', 'Lakeview Drive', 'Toronto', 'USA', 'Kentucky', '51459'),
       ('28', '100th Avenue', 'Houston', 'UK', 'England', 'TVEJUO'),
       ('11', 'High Street', 'Rio de Janeiro', 'Germany', 'Lower Saxony', '56335'),
       ('94', 'Forest Drive', 'San Diego', 'Germany', 'Bremen', '66957'),
       ('47', 'South Avenue', 'Brussels', 'USA', 'Maine', '83414'),
       ('87', 'West Boulevard', 'Cape Town', 'Canada', 'Alberta', 'VZ5W2N'),
       ('177A', 'North Street', 'Miami', 'USA', 'Hawaii', '87869'),
       ('90S', 'Pine Boulevard', 'Brussels', 'UK', 'England', 'F53XJT'),
       ('91', 'First Street', 'Ottawa', 'UK', 'Scotland', 'GWXH31'),
       ('106', 'Second Avenue', 'Bangkok', 'Australia', 'New South Wales', '0ZPTFK'),
       ('82', 'Southwest Lane', 'Philadelphia', 'Canada', 'Alberta', 'L8U9BP'),
       ('122', 'Main Street', 'San Antonio', 'USA', 'Iowa', '77937'),
       ('188T', '100th Avenue', 'Toronto', 'Australia', 'Victoria', '8CJGGP'),
       ('210', 'Riverside Drive', 'Jakarta', 'Australia', 'Western Australia', 'G197BX'),
       ('21', 'Park Avenue', 'Ottawa', 'Australia', 'South Australia', 'CKCF7Q'),
       ('218', '42nd Street', 'Osaka', 'Canada', 'Ontario', 'RTU8NN'),
       ('56', 'Sunset Boulevard', 'Brussels', 'Germany', 'Hamburg', '15956'),
       ('16T', 'Park Avenue', 'Los Angeles', 'USA', 'Delaware', '45667'),
       ('99', 'Main Street', 'London', 'Germany', 'Hamburg', '72440'),
       ('131B', 'Commerce Road', 'Ottawa', 'Germany', 'Hamburg', '88530'),
       ('286', '100th Avenue', 'Montreal', 'Germany', 'North Rhine-Westphalia', '35486'),
       ('8', 'Market Street', 'Osaka', 'Canada', 'Ontario', '20QQXX'),
       ('76', 'North Street', 'New York', 'UK', 'Greater London', 'BOP3WQ'),
       ('237', 'Tenth Avenue', 'Ottawa', 'UK', 'Greater London', '852HX1'),
       ('224', 'Hillside Avenue', 'Seoul', 'UK', 'England', 'E4WCG5'),
       ('109J', 'Northeast Drive', 'Dubai', 'Germany', 'Bremen', '64763'),
       ('254I', 'High Street', 'Osaka', 'Canada', 'Nova Scotia', 'E2CLB6'),
       ('269', '42nd Street', 'Cape Town', 'USA', 'Delaware', '83735'),
       ('214P', 'First Street', 'Vancouver', 'USA', 'Alaska', '79178'),
       ('193D', 'Market Street', 'Manchester', 'Canada', 'Nova Scotia', '1WKOEN'),
       ('262K', 'Northeast Drive', 'Berlin', 'UK', 'Greater London', '81EQZA'),
       ('255', 'Hillside Avenue', 'Dallas', 'Australia', 'Western Australia', '8QG0E1'),
       ('223', 'West Boulevard', 'Dallas', 'Germany', 'Bremen', '52007'),
       ('298', 'West Boulevard', 'Cape Town', 'Canada', 'Alberta', 'YQ3922'),
       ('81', 'Business Park Drive', 'Ottawa', 'Australia', 'New South Wales', 'KAV3I8'),
       ('230', 'Enterprise Street', 'Montreal', 'UK', 'Scotland', 'DABRCJ'),
       ('109', 'Southwest Lane', 'Toronto', 'USA', 'Florida', '25416'),
       ('285', 'Fifth Street', 'Montreal', 'Germany', 'Lower Saxony', '61419'),
       ('106', 'First Street', 'Madrid', 'Canada', 'Quebec', '5JDUFU'),
       ('141', 'Oak Avenue', 'Bangkok', 'Germany', 'Hamburg', '24989'),
       ('129', 'Industrial Avenue', 'Vancouver', 'Germany', 'Brandenburg', '13563'),
       ('26', 'Innovation Road', 'Johannesburg', 'USA', 'Florida', '90599'),
       ('102', 'Maple Road', 'Rio de Janeiro', 'Canada', 'New Brunswick', 'RSOKWM'),
       ('112', 'Innovation Road', 'Houston', 'Germany', 'Brandenburg', '12811'),
       ('174', 'Elm Street', 'Munich', 'USA', 'Colorado', '38938'),
       ('174', 'Business Park Drive', 'Mexico City', 'Germany', 'Bremen', '72264'),
       ('91L', 'Lakeview Drive', 'New York', 'UK', 'East Midlands', 'MAMFFI'),
       ('256S', 'Business Park Drive', 'Philadelphia', 'Canada', 'Manitoba', '7Q3ZJD'),
       ('232S', 'East Road', 'Vancouver', 'UK', 'East Midlands', '6EGM2W'),
       ('259', 'Maple Road', 'Cape Town', 'Australia', 'South Australia', 'BUG90G'),
       ('19', 'Maple Road', 'Philadelphia', 'Canada', 'Ontario', '8LDFOJ'),
       ('272Z', 'Sunset Boulevard', 'New York', 'Australia', 'Tasmania', 'DTS7FW'),
       ('273', 'Maple Road', 'Madrid', 'USA', 'Kansas', '23935'),
       ('57', 'Riverside Drive', 'Chicago', 'USA', 'Idaho', '87043'),
       ('197G', 'Second Avenue', 'Toronto', 'Australia', 'Western Australia', 'PO97VK'),
       ('266A', 'Riverside Drive', 'Amsterdam', 'Australia', 'Western Australia', '3F032U'),
       ('100', 'Northeast Drive', 'Los Angeles', 'Canada', 'British Columbia', 'XFCR2S'),
       ('298', 'Valley View Road', 'Manchester', 'USA', 'Arkansas', '53141'),
       ('185O', 'Main Street', 'Ottawa', 'Canada', 'Ontario', 'XDO210'),
       ('67J', 'Industrial Avenue', 'Toronto', 'Germany', 'North Rhine-Westphalia', '26131'),
       ('206', 'Tenth Avenue', 'Houston', 'UK', 'Scotland', 'Y1GWT8'),
       ('8', 'Southwest Lane', 'Phoenix', 'UK', 'Greater London', 'KKYMRG'),
       ('107V', 'Meadow Lane', 'Vienna', 'Australia', 'Tasmania', '35FCS6'),
       ('16Q', 'Fourth Avenue', 'Jakarta', 'USA', 'Idaho', '15914'),
       ('170', 'Tenth Avenue', 'Johannesburg', 'Canada', 'Newfoundland', 'PTYGN8'),
       ('177', '100th Avenue', 'Miami', 'Canada', 'Newfoundland', 'YZEOUB'),
       ('286', 'Tenth Avenue', 'Sydney', 'Germany', 'North Rhine-Westphalia', '48351'),
       ('68', 'Hillside Avenue', 'Osaka', 'Germany', 'Brandenburg', '85548'),
       ('157', 'Sunset Boulevard', 'Barcelona', 'Germany', 'Brandenburg', '15892'),
       ('103', 'Forest Drive', 'Mexico City', 'USA', 'Louisiana', '21977'),
       ('64T', 'Elm Street', 'Paris', 'Germany', 'Berlin', '18727'),
       ('263', 'Third Street', 'Tokyo', 'USA', 'Kentucky', '77968'),
       ('248', 'First Street', 'Singapore', 'Australia', 'Victoria', 'KQZU2U'),
       ('48', 'Market Street', 'London', 'USA', 'Arkansas', '34352'),
       ('192', 'East Road', 'Mexico City', 'UK', 'North West', 'IN9TNV'),
       ('274', 'Enterprise Street', 'Vancouver', 'UK', 'England', '7SQC9D'),
       ('292', 'Maple Road', 'New York', 'Canada', 'Nova Scotia', 'Q2GLQO'),
       ('116', 'Lakeview Drive', 'Jakarta', 'USA', 'Colorado', '29901'),
       ('4', 'Business Park Drive', 'Singapore', 'UK', 'South East', 'ZIYV4D'),
       ('72', 'Church Street', 'Toronto', 'USA', 'Hawaii', '72299'),
       ('88V', 'North Street', 'Prague', 'Australia', 'Tasmania', 'URPW87'),
       ('192M', 'East Road', 'Hong Kong', 'USA', 'Delaware', '25499'),
       ('228', 'Maple Road', 'Los Angeles', 'Canada', 'New Brunswick', '8O1E3I'),
       ('14T', 'Business Park Drive', 'Amsterdam', 'UK', 'East Midlands', 'UDWKIS'),
       ('90', '42nd Street', 'Berlin', 'USA', 'Hawaii', '78259'),
       ('294', 'Business Park Drive', 'Jakarta', 'UK', 'Wales', '7OF4K5'),
       ('100O', 'Innovation Road', 'Singapore', 'Germany', 'Hamburg', '12953'),
       ('22J', 'Technology Way', 'Bangkok', 'Australia', 'New South Wales', 'A005KX'),
       ('23', 'Northeast Drive', 'Vancouver', 'Australia', 'New South Wales', '0CLJ2H'),
       ('85', 'Maple Road', 'Dubai', 'UK', 'Northern Ireland', '09QPOO'),
       ('50', 'Technology Way', 'Amsterdam', 'Germany', 'Brandenburg', '19447'),
       ('126A', 'Mountain Road', 'Dubai', 'Australia', 'Victoria', 'QOOW8A'),
       ('1', 'Sunset Boulevard', 'Montreal', 'USA', 'Illinois', '10129'),
       ('265A', 'Hillside Avenue', 'Manchester', 'Australia', 'South Australia', 'GJD3N7'),
       ('159F', 'Riverside Drive', 'Houston', 'Canada', 'New Brunswick', 'ODTNK5'),
       ('257', 'Second Avenue', 'Hong Kong', 'USA', 'Louisiana', '48139'),
       ('75', 'Technology Way', 'Berlin', 'Canada', 'Ontario', 'NJQHNM'),
       ('132X', 'Meadow Lane', 'Mexico City', 'Australia', 'South Australia', 'BAPWEQ'),
       ('271B', 'Sunset Boulevard', 'Munich', 'USA', 'Hawaii', '74551'),
       ('256', 'Maple Road', 'Sao Paulo', 'USA', 'Indiana', '10847'),
       ('45O', 'Mountain Road', 'Sydney', 'Australia', 'Victoria', '1202DJ'),
       ('232', 'Third Street', 'Kuala Lumpur', 'Australia', 'Tasmania', 'Q5YYGM'),
       ('65', 'Pine Boulevard', 'London', 'UK', 'East Midlands', '4Z8H4B'),
       ('80Q', 'Corporate Boulevard', 'Vancouver', 'Canada', 'Manitoba', 'T4LAKB'),
       ('20', 'Forest Drive', 'Sydney', 'UK', 'England', 'NAU5XL'),
       ('139T', 'Lakeview Drive', 'Singapore', 'Germany', 'Berlin', '13324'),
       ('87', 'North Street', 'Toronto', 'Australia', 'Tasmania', 'B86I99'),
       ('206', 'Sunset Boulevard', 'Sydney', 'UK', 'Wales', '0WYBWF'),
       ('5', 'North Street', 'Sao Paulo', 'UK', 'England', 'ROI3LP'),
       ('41T', 'Elm Street', 'Johannesburg', 'Germany', 'North Rhine-Westphalia', '76246'),
       ('84', 'Oak Avenue', 'Prague', 'Canada', 'Alberta', '7B5FDR'),
       ('50', 'Lakeview Drive', 'Jakarta', 'Canada', 'New Brunswick', 'QVLRMX'),
       ('268', 'Valley View Road', 'Vienna', 'UK', 'Wales', '39Q98G'),
       ('187U', 'Innovation Road', 'Los Angeles', 'USA', 'Iowa', '52285'),
       ('257', 'West Boulevard', 'Hong Kong', 'Canada', 'Manitoba', '2I6BYY'),
       ('21Q', 'Valley View Road', 'Vienna', 'UK', 'South East', 'W4GNJ0'),
       ('60', '100th Avenue', 'Montreal', 'UK', 'Greater London', 'C05QCS'),
       ('103', '42nd Street', 'Amsterdam', 'Germany', 'Bremen', '35064'),
       ('151', 'Main Street', 'Johannesburg', 'Australia', 'Tasmania', '61BW7R'),
       ('169', 'Fifth Street', 'Dubai', 'Australia', 'South Australia', 'IOKAVY'),
       ('44', 'Technology Way', 'Munich', 'Canada', 'Manitoba', 'UU3GVN'),
       ('185', 'Riverside Drive', 'Philadelphia', 'Australia', 'South Australia', 'SCL31W'),
       ('136', 'Southwest Lane', 'Bangkok', 'USA', 'Arizona', '28842'),
       ('268W', 'Park Avenue', 'San Diego', 'UK', 'North West', 'FB3545'),
       ('96', 'Park Avenue', 'Berlin', 'Germany', 'North Rhine-Westphalia', '21485'),
       ('252', 'Lakeview Drive', 'Amsterdam', 'Australia', 'Queensland', 'OU4HRX'),
       ('297', 'Main Street', 'Hong Kong', 'Germany', 'Bremen', '96578'),
       ('297', 'Market Street', 'London', 'Canada', 'Alberta', 'Z858V5'),
       ('177', 'Second Avenue', 'Prague', 'Australia', 'Western Australia', 'XDXLB1'),
       ('230', 'Second Avenue', 'Ottawa', 'Australia', 'South Australia', 'UHY1T7'),
       ('79', 'Main Street', 'Munich', 'Germany', 'Bavaria', '52694'),
       ('261', 'First Street', 'Amsterdam', 'Canada', 'Alberta', 'X0K7XZ'),
       ('60', 'Business Park Drive', 'Osaka', 'Australia', 'New South Wales', 'NPTI9P'),
       ('93', 'West Boulevard', 'Bangkok', 'Australia', 'New South Wales', 'UFHMSJ'),
       ('261K', 'Business Park Drive', 'Brussels', 'Germany', 'North Rhine-Westphalia', '64515'),
       ('269', '100th Avenue', 'Mexico City', 'Canada', 'Quebec', '47MIV7'),
       ('238D', 'Lakeview Drive', 'San Antonio', 'UK', 'Greater London', 'OR9MNL'),
       ('217', 'East Road', 'Munich', 'Germany', 'Bremen', '55173'),
       ('192H', 'Business Park Drive', 'Dubai', 'UK', 'Scotland', '495QQ3'),
       ('238', 'Fourth Avenue', 'Johannesburg', 'UK', 'East Midlands', 'JKVK04'),
       ('107', 'Industrial Avenue', 'Vancouver', 'USA', 'Idaho', '91974'),
       ('225', 'Industrial Avenue', 'Madrid', 'UK', 'Scotland', 'I5ZLXS'),
       ('198V', '100th Avenue', 'Rome', 'Canada', 'Nova Scotia', 'UPNU8B'),
       ('191', 'Industrial Avenue', 'Vancouver', 'USA', 'Maine', '46419'),
       ('266', 'Church Street', 'Sydney', 'Germany', 'Lower Saxony', '87909'),
       ('157', 'Fourth Avenue', 'Jakarta', 'UK', 'North West', '8TJNKN'),
       ('276', 'South Avenue', 'Vancouver', 'Germany', 'Berlin', '76650'),
       ('164', 'Church Street', 'Mexico City', 'Canada', 'Alberta', 'BWJ0VY'),
       ('59', 'Hillside Avenue', 'New York', 'Germany', 'Berlin', '11830'),
       ('221', 'South Avenue', 'Lyon', 'UK', 'Wales', 'PWOFSP'),
       ('275', 'Park Avenue', 'Johannesburg', 'USA', 'Maine', '66824'),
       ('8R', 'Industrial Avenue', 'San Diego', 'USA', 'Maine', '76805'),
       ('286', 'First Street', 'Jakarta', 'UK', 'North West', 'GHDYSX'),
       ('237D', 'East Road', 'Sydney', 'Canada', 'Nova Scotia', '26LFAK'),
       ('261', 'High Street', 'Johannesburg', 'UK', 'East Midlands', 'IXXYN5'),
       ('80', 'Market Street', 'Seoul', 'Canada', 'New Brunswick', 'MBBXHQ'),
       ('253N', '100th Avenue', 'Rio de Janeiro', 'UK', 'East Midlands', 'WD02JJ'),
       ('292O', 'Oak Avenue', 'Rio de Janeiro', 'Australia', 'New South Wales', 'TRHURW'),
       ('58', 'Oak Avenue', 'Berlin', 'Germany', 'Bremen', '27982'),
       ('7F', 'Riverside Drive', 'Dubai', 'Australia', 'New South Wales', 'OFTDUX'),
       ('246', 'South Avenue', 'Birmingham', 'UK', 'Greater London', 'JHR99B'),
       ('32', 'Commerce Road', 'Phoenix', 'UK', 'North West', '8Z15CV'),
       ('25W', 'Commerce Road', 'Montreal', 'USA', 'Delaware', '41664'),
       ('194A', 'Oak Avenue', 'Johannesburg', 'UK', 'North West', '4ICO90'),
       ('236', 'Tenth Avenue', 'Rome', 'Australia', 'Victoria', '97N6Q2'),
       ('203B', 'Southwest Lane', 'Melbourne', 'UK', 'Wales', 'US1MME'),
       ('1N', 'Forest Drive', 'Los Angeles', 'Germany', 'Bavaria', '97074'),
       ('62', 'Business Park Drive', 'Chicago', 'Australia', 'South Australia', 'JT5UFT'),
       ('121', 'Second Avenue', 'Sydney', 'UK', 'East Midlands', '989BOR'),
       ('251', 'West Boulevard', 'Amsterdam', 'Australia', 'Tasmania', 'S5KP9Q'),
       ('85', 'Third Street', 'Vancouver', 'Australia', 'Queensland', '3CSSSO'),
       ('175', 'Valley View Road', 'San Diego', 'UK', 'North West', '5907WS'),
       ('153', 'Corporate Boulevard', 'Dallas', 'Germany', 'Hesse', '68935'),
       ('76', 'Forest Drive', 'Houston', 'Canada', 'Manitoba', '9ZFZ1T'),
       ('143', 'South Avenue', 'Jakarta', 'Germany', 'Hesse', '26821'),
       ('83', 'Meadow Lane', 'Johannesburg', 'Australia', 'Western Australia', 'BDTOUZ'),
       ('245', 'Fourth Avenue', 'Birmingham', 'UK', 'North West', '2JYNVO'),
       ('32I', 'Enterprise Street', 'Amsterdam', 'USA', 'Kentucky', '83798'),
       ('16', 'Park Avenue', 'Amsterdam', 'Australia', 'Western Australia', 'L7QMNS'),
       ('194', 'First Street', 'Montreal', 'USA', 'Kansas', '33902'),
       ('92', 'South Avenue', 'Brussels', 'Australia', 'Tasmania', 'Z2OAGP'),
       ('221M', 'Market Street', 'Amsterdam', 'Germany', 'Hamburg', '78296'),
       ('284', 'High Street', 'Osaka', 'Canada', 'Ontario', 'L44QXF'),
       ('277N', 'Meadow Lane', 'Chicago', 'Canada', 'Nova Scotia', 'J0ENHX'),
       ('143', 'Sunset Boulevard', 'Osaka', 'Canada', 'Ontario', 'WHBQ7J'),
       ('127', 'Elm Street', 'Amsterdam', 'Australia', 'Victoria', '52L6FO'),
       ('204', 'Enterprise Street', 'Hong Kong', 'USA', 'Arizona', '56795'),
       ('202', 'High Street', 'London', 'Canada', 'Quebec', '3LJY5H'),
       ('215', 'Sunset Boulevard', 'Mexico City', 'Canada', 'Nova Scotia', 'RGOARQ'),
       ('222', 'First Street', 'London', 'Germany', 'Hamburg', '33558'),
       ('88', 'High Street', 'Chicago', 'Germany', 'North Rhine-Westphalia', '73073'),
       ('47', 'Maple Road', 'Rio de Janeiro', 'Germany', 'North Rhine-Westphalia', '61683'),
       ('279', 'Pine Boulevard', 'Johannesburg', 'Australia', 'Western Australia', 'QVYTEK'),
       ('121', 'Meadow Lane', 'Munich', 'Australia', 'South Australia', 'N0AHQU'),
       ('47', 'Forest Drive', 'Phoenix', 'Canada', 'Manitoba', '1J79Q4'),
       ('22', 'Industrial Avenue', 'Philadelphia', 'UK', 'England', 'EU190I'),
       ('128', 'West Boulevard', 'Hong Kong', 'Germany', 'Lower Saxony', '49321'),
       ('90', 'Corporate Boulevard', 'Dubai', 'Australia', 'Queensland', 'OPTJ8C'),
       ('184E', 'Northeast Drive', 'Berlin', 'Australia', 'Tasmania', '7CBIQ1'),
       ('240', 'Third Street', 'Rome', 'UK', 'North West', 'HPXRY0'),
       ('206R', 'Lakeview Drive', 'Los Angeles', 'UK', 'North West', '7RTPTD'),
       ('219', 'Elm Street', 'Rome', 'Australia', 'Victoria', 'JXB36N'),
       ('99E', 'High Street', 'Lyon', 'UK', 'South East', 'YG5NZM'),
       ('221C', 'Elm Street', 'Cape Town', 'Canada', 'British Columbia', '9OJ2UU'),
       ('213C', 'Forest Drive', 'Mexico City', 'UK', 'England', 'SFHQ36'),
       ('141', 'Northeast Drive', 'Philadelphia', 'Canada', 'Manitoba', 'TXWE93'),
       ('28', 'Sunset Boulevard', 'Ottawa', 'Australia', 'Tasmania', 'NXS9WO'),
       ('204', 'Southwest Lane', 'Ottawa', 'Germany', 'Hesse', '23329'),
       ('258', 'Third Street', 'Kuala Lumpur', 'Germany', 'Hamburg', '47276'),
       ('234C', 'West Boulevard', 'Birmingham', 'USA', 'Maine', '44490'),
       ('215', 'Park Avenue', 'Dallas', 'Australia', 'Tasmania', 'KY037S'),
       ('220', 'Business Park Drive', 'Sydney', 'Australia', 'South Australia', 'LODODK'),
       ('273', 'Enterprise Street', 'Hong Kong', 'Canada', 'Ontario', 'G1STDQ'),
       ('143I', 'North Street', 'Tokyo', 'Canada', 'Nova Scotia', 'YW1YEN'),
       ('232', '100th Avenue', 'Paris', 'Australia', 'Western Australia', '2I5YSG'),
       ('69', 'Riverside Drive', 'Prague', 'UK', 'North West', 'F0IZQB'),
       ('76F', 'West Boulevard', 'Paris', 'UK', 'East Midlands', '2TRKZU'),
       ('102', 'Market Street', 'Ottawa', 'Canada', 'New Brunswick', 'M2RBS2'),
       ('257', 'Technology Way', 'Milan', 'UK', 'East Midlands', 'S974A3'),
       ('256', 'Business Park Drive', 'Barcelona', 'Canada', 'New Brunswick', 'PG9H31'),
       ('242', 'Oak Avenue', 'Toronto', 'UK', 'North West', 'J30P0V'),
       ('36', '42nd Street', 'Jakarta', 'Australia', 'South Australia', 'H4I318'),
       ('16U', 'Maple Road', 'Vancouver', 'Australia', 'Queensland', 'O2ERPI'),
       ('285', 'Fourth Avenue', 'Brussels', 'Germany', 'Hamburg', '59558'),
       ('187', 'Corporate Boulevard', 'Berlin', 'USA', 'Maine', '31310'),
       ('286', 'Main Street', 'London', 'UK', 'East Midlands', 'BZIAAT'),
       ('24', 'Market Street', 'Osaka', 'Australia', 'South Australia', 'VXTMFT'),
       ('205', 'Innovation Road', 'Houston', 'UK', 'Greater London', 'GLTCY8'),
       ('160', 'North Street', 'Paris', 'Canada', 'Quebec', 'RNDVM7'),
       ('241', 'Tenth Avenue', 'Houston', 'Australia', 'South Australia', 'HYEQQC'),
       ('172', 'Mountain Road', 'Lyon', 'Australia', 'Western Australia', 'W3XTZT'),
       ('64R', 'Main Street', 'San Diego', 'UK', 'Northern Ireland', 'OG686E'),
       ('126', 'Meadow Lane', 'Tokyo', 'Canada', 'British Columbia', 'TEQKQL'),
       ('32', 'Technology Way', 'Dubai', 'Germany', 'Hamburg', '84618'),
       ('227', 'Main Street', 'Philadelphia', 'Australia', 'Western Australia', 'KUT1G0'),
       ('259', 'Sunset Boulevard', 'Osaka', 'Germany', 'Berlin', '90627'),
       ('274', 'Fifth Street', 'San Antonio', 'USA', 'Alaska', '33464'),
       ('294', 'Cedar Lane', 'Vienna', 'UK', 'Wales', 'T37XGB'),
       ('42', '42nd Street', 'San Diego', 'Germany', 'Bremen', '49369'),
       ('141', 'Forest Drive', 'Cape Town', 'USA', 'Hawaii', '95738'),
       ('110Z', 'Pine Boulevard', 'Milan', 'Germany', 'Hamburg', '63263'),
       ('244Z', 'West Boulevard', 'Singapore', 'Canada', 'Quebec', '0BX9ON'),
       ('130', 'Lakeview Drive', 'San Antonio', 'Australia', 'Victoria', 'CZJ914'),
       ('210', 'Commerce Road', 'Jakarta', 'Australia', 'Victoria', 'LONE3Z'),
       ('123', 'Park Avenue', 'Tokyo', 'Canada', 'British Columbia', 'QK04HY'),
       ('103', 'First Street', 'Montreal', 'Australia', 'Western Australia', 'V33F0W'),
       ('123', 'High Street', 'Tokyo', 'UK', 'Greater London', 'GHLBVD'),
       ('71', 'Cedar Lane', 'Brussels', 'Germany', 'Hesse', '22810'),
       ('287', 'Sunset Boulevard', 'Vienna', 'USA', 'Connecticut', '95326'),
       ('61W', 'Park Avenue', 'Milan', 'Canada', 'Nova Scotia', '55FQ6G'),
       ('152', 'Tenth Avenue', 'San Diego', 'Germany', 'Hamburg', '69364'),
       ('70', 'Forest Drive', 'Amsterdam', 'Australia', 'Queensland', 'XGIN0O'),
       ('98', 'Cedar Lane', 'Jakarta', 'Germany', 'Hesse', '95603'),
       ('101', 'Park Avenue', 'Seoul', 'Germany', 'Brandenburg', '86159'),
       ('88', 'Valley View Road', 'Ottawa', 'Canada', 'Quebec', 'JP1M2U'),
       ('96L', 'North Street', 'Barcelona', 'Germany', 'Berlin', '72056'),
       ('298I', 'Tenth Avenue', 'Houston', 'USA', 'Arizona', '49528'),
       ('185', 'Cedar Lane', 'Johannesburg', 'Germany', 'Hamburg', '46239'),
       ('45', 'Market Street', 'Chicago', 'Germany', 'Bavaria', '90667'),
       ('2', 'Main Street', 'Johannesburg', 'Germany', 'Bavaria', '25377'),
       ('66T', 'Fourth Avenue', 'Barcelona', 'Australia', 'Queensland', 'XBL9IN'),
       ('183', 'Tenth Avenue', 'Berlin', 'Germany', 'Brandenburg', '48298'),
       ('92S', '100th Avenue', 'Brussels', 'Germany', 'Bavaria', '69198'),
       ('210', 'First Street', 'San Diego', 'Germany', 'Hamburg', '15859'),
       ('227', 'Market Street', 'Barcelona', 'Germany', 'Bavaria', '46609'),
       ('86', 'Corporate Boulevard', 'Houston', 'USA', 'Louisiana', '41796'),
       ('218', 'Valley View Road', 'Miami', 'Canada', 'Newfoundland', '2OGGTG'),
       ('232', 'High Street', 'Brussels', 'Germany', 'Hamburg', '12953'),
       ('68R', 'Sunset Boulevard', 'Tokyo', 'Canada', 'Quebec', 'QZ1DZY'),
       ('277', 'Meadow Lane', 'Vienna', 'Germany', 'Bremen', '90313'),
       ('137', 'Southwest Lane', 'Montreal', 'USA', 'Kentucky', '30189'),
       ('253', 'Innovation Road', 'San Antonio', 'Australia', 'Western Australia', 'OQZIHW'),
       ('118', 'Innovation Road', 'Barcelona', 'Canada', 'Quebec', '7G1NMF'),
       ('23', 'Lakeview Drive', 'New York', 'Canada', 'Alberta', 'E6RNXT'),
       ('227', 'Oak Avenue', 'Tokyo', 'USA', 'Alabama', '19765'),
       ('120', 'Tenth Avenue', 'Osaka', 'Australia', 'Queensland', 'C8FIPM'),
       ('99', 'Commerce Road', 'Singapore', 'UK', 'England', '2HIFE8'),
       ('229', 'Northeast Drive', 'Melbourne', 'UK', 'South East', '8T9OKG'),
       ('134R', 'Industrial Avenue', 'Dallas', 'USA', 'Idaho', '34051'),
       ('230Z', 'Mountain Road', 'Munich', 'USA', 'Delaware', '81033'),
       ('187V', 'Market Street', 'Rome', 'Canada', 'British Columbia', 'CN1KU7'),
       ('35', 'Pine Boulevard', 'London', 'USA', 'Illinois', '70381'),
       ('169', 'Enterprise Street', 'Mexico City', 'Germany', 'Hamburg', '91796'),
       ('181L', 'Northeast Drive', 'Johannesburg', 'Canada', 'Quebec', '7RZ2GS'),
       ('68', 'Mountain Road', 'San Antonio', 'USA', 'Maryland', '92447'),
       ('68', 'Cedar Lane', 'Johannesburg', 'Australia', 'Victoria', 'KM6QGG'),
       ('229', 'Meadow Lane', 'Houston', 'Australia', 'Tasmania', '0DZIQY'),
       ('148', 'Elm Street', 'Montreal', 'Canada', 'Alberta', 'M6BHN9'),
       ('65', 'Third Street', 'Sydney', 'UK', 'Greater London', '02MPQ1'),
       ('64', 'Enterprise Street', 'Hong Kong', 'UK', 'Northern Ireland', 'ZF9HX3'),
       ('55B', 'Valley View Road', 'Jakarta', 'UK', 'Greater London', 'RNT4PP'),
       ('213W', 'Oak Avenue', 'Milan', 'Germany', 'Hamburg', '24056'),
       ('281', 'Industrial Avenue', 'Philadelphia', 'USA', 'Delaware', '47120'),
       ('261', 'Lakeview Drive', 'Osaka', 'Germany', 'Brandenburg', '45205'),
       ('51', 'Forest Drive', 'San Antonio', 'USA', 'Indiana', '24829'),
       ('159', 'Technology Way', 'Montreal', 'Canada', 'Newfoundland', 'LTOA7D'),
       ('119', 'Fifth Street', 'Berlin', 'Germany', 'Brandenburg', '34171'),
       ('227', 'Hillside Avenue', 'Montreal', 'Germany', 'Hesse', '37475'),
       ('36', 'Sunset Boulevard', 'Miami', 'Germany', 'Brandenburg', '52533'),
       ('8E', 'Technology Way', 'Milan', 'UK', 'Wales', 'Z4KWYP'),
       ('271', '100th Avenue', 'Lyon', 'UK', 'Wales', 'H0KSZN'),
       ('203', 'Fifth Street', 'New York', 'USA', 'Kentucky', '30774'),
       ('23', 'Mountain Road', 'Milan', 'Germany', 'Lower Saxony', '25852'),
       ('155', 'Mountain Road', 'Paris', 'UK', 'Wales', 'JRASC1'),
       ('33', 'Maple Road', 'Toronto', 'Canada', 'Manitoba', '59Z9BD'),
       ('81', 'Hillside Avenue', 'Mexico City', 'Australia', 'Tasmania', '4CVYZJ'),
       ('38', '100th Avenue', 'Jakarta', 'Germany', 'Hamburg', '29825'),
       ('189', 'First Street', 'San Antonio', 'USA', 'Florida', '49714'),
       ('114', 'Cedar Lane', 'Jakarta', 'USA', 'California', '34124'),
       ('231', '100th Avenue', 'Jakarta', 'Canada', 'British Columbia', 'IJEGFO'),
       ('207', 'Lakeview Drive', 'Lyon', 'Germany', 'Hamburg', '68753'),
       ('53', 'Lakeview Drive', 'Madrid', 'USA', 'Alabama', '79212'),
       ('25', 'Hillside Avenue', 'Montreal', 'UK', 'Northern Ireland', '0FU1JH'),
       ('218', 'Tenth Avenue', 'Madrid', 'USA', 'Idaho', '76458'),
       ('250', '42nd Street', 'Miami', 'Australia', 'South Australia', 'Z0SU17'),
       ('155', 'Northeast Drive', 'Phoenix', 'Germany', 'Hamburg', '76366'),
       ('240', 'Innovation Road', 'Houston', 'Germany', 'Hesse', '11281'),
       ('113', 'Church Street', 'Manchester', 'Australia', 'Victoria', 'TZM5UP'),
       ('104', '100th Avenue', 'Mexico City', 'Australia', 'Western Australia', 'SMLWC3'),
       ('180', 'High Street', 'Manchester', 'Canada', 'Manitoba', 'MGKQVM'),
       ('219P', 'Third Street', 'Montreal', 'UK', 'England', 'TS2WZU'),
       ('226', 'Tenth Avenue', 'Lyon', 'USA', 'Arizona', '33557'),
       ('237', 'Main Street', 'Hong Kong', 'Canada', 'Quebec', 'L8PLRG'),
       ('177', 'Sunset Boulevard', 'Bangkok', 'Canada', 'New Brunswick', 'E56WHV'),
       ('193', 'Valley View Road', 'Bangkok', 'USA', 'Louisiana', '95611'),
       ('59', 'Maple Road', 'Los Angeles', 'USA', 'Illinois', '26733'),
       ('86', 'South Avenue', 'Brussels', 'UK', 'North West', 'ELEXYP'),
       ('57', 'Pine Boulevard', 'Rome', 'Australia', 'Victoria', '48HZ7L'),
       ('52S', 'Sunset Boulevard', 'Miami', 'Canada', 'Ontario', 'FAIB65'),
       ('295', 'Forest Drive', 'Phoenix', 'USA', 'Florida', '26447'),
       ('116', 'Second Avenue', 'New York', 'Canada', 'Nova Scotia', 'EF60SW'),
       ('141J', 'Industrial Avenue', 'Birmingham', 'UK', 'Greater London', '5NSDDQ'),
       ('233', 'Cedar Lane', 'London', 'Canada', 'Manitoba', 'Q9WM09'),
       ('149', 'Northeast Drive', 'Johannesburg', 'Australia', 'Queensland', 'QO090V'),
       ('225Q', 'Pine Boulevard', 'Melbourne', 'Germany', 'Bavaria', '32621'),
       ('181V', 'Main Street', 'Dubai', 'USA', 'Georgia', '44083'),
       ('254A', 'Tenth Avenue', 'Mexico City', 'Australia', 'Western Australia', 'LLBGDT'),
       ('100G', 'Sunset Boulevard', 'Milan', 'UK', 'Wales', 'KMBY9D'),
       ('295', 'Forest Drive', 'Jakarta', 'Germany', 'North Rhine-Westphalia', '70976'),
       ('193', 'Northeast Drive', 'Jakarta', 'Canada', 'British Columbia', 'V1OQO4'),
       ('118', 'Valley View Road', 'Dallas', 'Canada', 'Nova Scotia', '4CRJZN'),
       ('190', 'Church Street', 'Sydney', 'Germany', 'Berlin', '33146'),
       ('81', 'Market Street', 'Rome', 'USA', 'Delaware', '27594'),
       ('47G', 'Church Street', 'San Diego', 'UK', 'Northern Ireland', 'VIZATV'),
       ('35M', '42nd Street', 'Mexico City', 'Germany', 'Bavaria', '47467'),
       ('280', 'Northeast Drive', 'Jakarta', 'UK', 'North West', '1RJA81'),
       ('202', 'Church Street', 'Vienna', 'Germany', 'Hamburg', '60450'),
       ('292', 'Fifth Street', 'Rio de Janeiro', 'UK', 'North West', 'R67YDM'),
       ('48K', 'Sunset Boulevard', 'Cape Town', 'Germany', 'North Rhine-Westphalia', '99990'),
       ('270', 'Third Street', 'Munich', 'USA', 'Colorado', '69932'),
       ('43', 'Valley View Road', 'Melbourne', 'USA', 'Kentucky', '70070'),
       ('82', 'Pine Boulevard', 'Berlin', 'Germany', 'Berlin', '49951'),
       ('137', 'Meadow Lane', 'Brussels', 'Canada', 'Quebec', 'AJTTDY'),
       ('14', 'Industrial Avenue', 'Los Angeles', 'Australia', 'Queensland', 'GEVSUY'),
       ('93F', 'Commerce Road', 'Singapore', 'UK', 'North West', '4WJU0C'),
       ('168', 'South Avenue', 'Lyon', 'Germany', 'Lower Saxony', '40256'),
       ('59', 'Valley View Road', 'Prague', 'UK', 'Northern Ireland', 'LGEDRM'),
       ('145', 'Maple Road', 'Ottawa', 'Germany', 'Berlin', '25448'),
       ('140G', 'High Street', 'Houston', 'USA', 'Colorado', '48232'),
       ('126', 'Park Avenue', 'London', 'Germany', 'North Rhine-Westphalia', '75912'),
       ('186', 'Northeast Drive', 'Houston', 'Canada', 'British Columbia', '8ARMBL'),
       ('207', '100th Avenue', 'Sao Paulo', 'Germany', 'Hesse', '91146'),
       ('210', 'Park Avenue', 'Munich', 'Germany', 'Bremen', '23295'),
       ('144W', 'Sunset Boulevard', 'Lyon', 'Canada', 'Newfoundland', 'CM3KC2'),
       ('173', 'Southwest Lane', 'Kuala Lumpur', 'Germany', 'North Rhine-Westphalia', '35007'),
       ('123', 'High Street', 'Mexico City', 'UK', 'East Midlands', 'S9LAD9'),
       ('142F', 'Second Avenue', 'Jakarta', 'USA', 'California', '39214'),
       ('63', 'Technology Way', 'Milan', 'UK', 'Greater London', 'KBXKE4'),
       ('296', 'North Street', 'Ottawa', 'UK', 'Scotland', '0U80ZL'),
       ('208', 'North Street', 'Los Angeles', 'Canada', 'Nova Scotia', 'HQPKS8'),
       ('152', 'Riverside Drive', 'Sydney', 'Canada', 'Nova Scotia', '2Y33HV'),
       ('207H', 'East Road', 'Lyon', 'Australia', 'Western Australia', '64L14P'),
       ('51', 'Forest Drive', 'Rio de Janeiro', 'UK', 'South East', 'PLZFKO'),
       ('172', 'Oak Avenue', 'Rio de Janeiro', 'USA', 'Connecticut', '50095'),
       ('272', 'Mountain Road', 'Vienna', 'Australia', 'South Australia', '1EGK77'),
       ('182', 'Maple Road', 'Ottawa', 'Canada', 'Alberta', 'XKXMK6'),
       ('214', 'Northeast Drive', 'Mexico City', 'UK', 'England', 'Q1826N'),
       ('93', 'Forest Drive', 'Prague', 'Germany', 'Berlin', '96005'),
       ('187', 'Lakeview Drive', 'Toronto', 'Germany', 'North Rhine-Westphalia', '75640'),
       ('3R', 'Third Street', 'Amsterdam', 'Canada', 'Newfoundland', 'S6FCOY'),
       ('206', 'Mountain Road', 'Manchester', 'Canada', 'Ontario', 'M29K3J'),
       ('169K', 'Pine Boulevard', 'Hong Kong', 'UK', 'Scotland', 'CIEDNX'),
       ('154', 'Oak Avenue', 'Bangkok', 'UK', 'South East', 'AIS9DO'),
       ('203', 'West Boulevard', 'Brussels', 'Australia', 'Tasmania', '4WF0Y8'),
       ('199', 'Southwest Lane', 'Prague', 'Australia', 'South Australia', '2H9XML'),
       ('268', '42nd Street', 'Los Angeles', 'UK', 'England', 'HM5VIU'),
       ('164', 'Elm Street', 'San Antonio', 'USA', 'Alabama', '86892'),
       ('220', 'Second Avenue', 'Rome', 'Australia', 'Tasmania', '52R7Z0'),
       ('81', 'Pine Boulevard', 'Brussels', 'Australia', 'Tasmania', 'WVL23S'),
       ('39Z', 'Industrial Avenue', 'Sao Paulo', 'Canada', 'Manitoba', 'SKFIFR'),
       ('44I', 'Elm Street', 'Sydney', 'Canada', 'Quebec', '5CST3M'),
       ('162', 'Elm Street', 'Rome', 'Germany', 'Brandenburg', '92920'),
       ('280', 'North Street', 'Brussels', 'Canada', 'Nova Scotia', 'QIRT84'),
       ('197', 'High Street', 'Houston', 'Australia', 'Victoria', 'BUX0RW'),
       ('107C', 'Church Street', 'Brussels', 'Canada', 'New Brunswick', 'DW5HN8'),
       ('187', 'Tenth Avenue', 'Rome', 'UK', 'East Midlands', 'P5V0LQ'),
       ('98Y', 'Fourth Avenue', 'Singapore', 'USA', 'Hawaii', '29366'),
       ('206', 'Oak Avenue', 'Miami', 'Germany', 'Hesse', '84694'),
       ('287H', 'Market Street', 'San Antonio', 'Canada', 'Newfoundland', '95Z5VU'),
       ('67T', 'Business Park Drive', 'Johannesburg', 'Germany', 'Brandenburg', '64433'),
       ('40', 'High Street', 'Madrid', 'Germany', 'Bavaria', '27610'),
       ('52', 'Valley View Road', 'Birmingham', 'Canada', 'British Columbia', 'Z35JFX'),
       ('112', 'Enterprise Street', 'Kuala Lumpur', 'Canada', 'New Brunswick', 'NMNHRM'),
       ('193', 'Meadow Lane', 'Birmingham', 'Germany', 'Berlin', '95103'),
       ('295', 'Enterprise Street', 'Bangkok', 'Germany', 'Bremen', '83246'),
       ('289', 'Pine Boulevard', 'Melbourne', 'UK', 'East Midlands', 'Q7HY4X'),
       ('275', 'East Road', 'Osaka', 'Germany', 'North Rhine-Westphalia', '84088'),
       ('49', '100th Avenue', 'Rio de Janeiro', 'Canada', 'Nova Scotia', 'C2C529'),
       ('55', 'Forest Drive', 'Bangkok', 'Australia', 'Victoria', '161C6F'),
       ('199', 'Elm Street', 'Jakarta', 'Canada', 'Alberta', '69BR9L'),
       ('285', 'Third Street', 'Philadelphia', 'Germany', 'Lower Saxony', '45497'),
       ('220', 'Main Street', 'Sao Paulo', 'Australia', 'Western Australia', 'P45WCD'),
       ('202', 'Cedar Lane', 'Rome', 'UK', 'Wales', 'XP2MGV'),
       ('211', 'Maple Road', 'Amsterdam', 'UK', 'North West', '8WR7PZ'),
       ('84', 'Elm Street', 'Hong Kong', 'UK', 'North West', 'BCUAWP'),
       ('109K', 'Fourth Avenue', 'Rome', 'Australia', 'New South Wales', 'DC367G'),
       ('30M', 'Meadow Lane', 'Birmingham', 'Australia', 'New South Wales', 'QBDLYR'),
       ('299', 'Meadow Lane', 'Singapore', 'Canada', 'New Brunswick', 'QQBBCI'),
       ('206', 'Tenth Avenue', 'San Diego', 'Germany', 'Brandenburg', '27558'),
       ('67W', 'Commerce Road', 'London', 'Canada', 'Manitoba', '4M69CV'),
       ('162M', 'High Street', 'Amsterdam', 'USA', 'Alabama', '45489'),
       ('187N', 'Fifth Street', 'Philadelphia', 'USA', 'Illinois', '65124'),
       ('257', '100th Avenue', 'Montreal', 'Canada', 'New Brunswick', 'OBY450'),
       ('168', 'South Avenue', 'San Antonio', 'UK', 'Scotland', 'AM3LD7'),
       ('287U', 'Main Street', 'San Antonio', 'Germany', 'Hesse', '76982'),
       ('13', 'South Avenue', 'Sydney', 'Germany', 'Lower Saxony', '21234'),
       ('201', 'Enterprise Street', 'San Antonio', 'Canada', 'British Columbia', 'ZULW13'),
       ('173', 'Meadow Lane', 'Berlin', 'Australia', 'New South Wales', 'PH90WA'),
       ('63J', 'Fourth Avenue', 'Phoenix', 'Canada', 'Newfoundland', 'KBP5FJ'),
       ('209H', 'West Boulevard', 'Sydney', 'Australia', 'South Australia', 'EUHR0Y'),
       ('172', 'Technology Way', 'Madrid', 'Canada', 'New Brunswick', 'K24TB2'),
       ('143', 'Pine Boulevard', 'Milan', 'UK', 'North West', '9WV52E'),
       ('220X', 'Meadow Lane', 'Brussels', 'Canada', 'Newfoundland', 'OKKW39'),
       ('54E', 'Fifth Street', 'Seoul', 'USA', 'Idaho', '68322'),
       ('29', 'South Avenue', 'Rio de Janeiro', 'Australia', 'Victoria', 'E1XVPR'),
       ('189X', 'Innovation Road', 'Montreal', 'Canada', 'Quebec', '0A8LCH'),
       ('149', 'East Road', 'Seoul', 'UK', 'Wales', 'W7CXD5'),
       ('207', 'Southwest Lane', 'Johannesburg', 'Canada', 'Quebec', '4UL356'),
       ('100', 'Church Street', 'Brussels', 'USA', 'Maryland', '61648'),
       ('297', 'Southwest Lane', 'Chicago', 'Germany', 'Hesse', '47422'),
       ('121', 'Mountain Road', 'Osaka', 'Australia', 'Western Australia', 'VFRKW3'),
       ('275', 'Meadow Lane', 'Miami', 'UK', 'Greater London', 'SLIDOF'),
       ('200I', 'Oak Avenue', 'Miami', 'Canada', 'Quebec', 'NWTJ9D'),
       ('154', 'Forest Drive', 'New York', 'Germany', 'Brandenburg', '47084'),
       ('45', 'Oak Avenue', 'Barcelona', 'Germany', 'Brandenburg', '56334'),
       ('99', 'Second Avenue', 'Osaka', 'Germany', 'Brandenburg', '37422'),
       ('39', '100th Avenue', 'Jakarta', 'Canada', 'New Brunswick', 'HRSA0F'),
       ('261', 'Industrial Avenue', 'Cape Town', 'USA', 'Kansas', '14012'),
       ('267P', 'Tenth Avenue', 'Chicago', 'Canada', 'British Columbia', 'T2NU9L'),
       ('158', '100th Avenue', 'Los Angeles', 'Germany', 'Lower Saxony', '42377'),
       ('244', 'Mountain Road', 'Rio de Janeiro', 'USA', 'Alaska', '92562'),
       ('32', 'Hillside Avenue', 'Bangkok', 'Australia', 'New South Wales', 'TO6SRC'),
       ('159F', 'Forest Drive', 'Munich', 'UK', 'Scotland', 'D946E9'),
       ('27D', 'Business Park Drive', 'Madrid', 'Germany', 'Bremen', '40120'),
       ('231', 'Riverside Drive', 'Seoul', 'Canada', 'Ontario', 'NXDLHK'),
       ('74', 'Third Street', 'Vienna', 'Germany', 'Bavaria', '34726');
COMMIT;

------------------------------------------------------------------------




CREATE OR REPLACE FUNCTION employee_name_change() RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employee_name_history (employee_id, first_name, second_name, last_name, start_ts)
        VALUES (NEW.id, NEW.first_name, NEW.second_name, NEW.last_name, now());

    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.first_name IS DISTINCT FROM OLD.first_name
            OR NEW.second_name IS DISTINCT FROM OLD.second_name
            OR NEW.last_name IS DISTINCT FROM OLD.last_name THEN

            UPDATE employee_name_history
            SET end_ts = now()
            WHERE employee_id = OLD.id
              AND end_ts IS NULL;

            INSERT INTO employee_name_history (employee_id, first_name, second_name, last_name, start_ts)
            VALUES (NEW.id, NEW.first_name, NEW.second_name, NEW.last_name, now());
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER employee_name_change
    AFTER INSERT OR UPDATE
    ON employees
    FOR EACH ROW
EXECUTE FUNCTION employee_name_change();

BEGIN;
INSERT INTO departments (name, head_id)
VALUES ('HR Department', 1),
       ('IT Department', 2),
       ('Finance Department', 3),
       ('Marketing Department', 4),
       ('Sales Department', 5),
       ('Legal Department', 6),
       ('Customer Support', 7),
       ('Operations Department', 8),
       ('R&D Department', 9),
       ('Administration', NULL);
COMMIT;


------------------------------------------------------------------------



CREATE OR REPLACE FUNCTION check_and_close_position() RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (SELECT 1
               FROM employee_positions_history
               WHERE employee_id = NEW.employee_id
                 AND NOT (
                   COALESCE(NEW.end_date, DATE '9999-12-31') < start_date OR
                   NEW.start_date > COALESCE(end_date, DATE '9999-12-31')
                   )) THEN
        RAISE EXCEPTION 'Overlapping position period for employee %', NEW.employee_id;
    END IF;



    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_and_close_position
    BEFORE INSERT OR UPDATE
    ON employee_positions_history
    FOR EACH ROW
EXECUTE FUNCTION check_and_close_position();


------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION check_single_active_position() RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF EXISTS (SELECT 1
                   FROM employee_positions_history eph
                   WHERE eph.employee_id = NEW.employee_id
                     AND eph.end_date IS NULL
                     AND eph.position <> NEW.position) THEN
            RAISE EXCEPTION 'Employee already has an active position';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_single_active_position
    BEFORE INSERT OR UPDATE
    ON employee_positions_history
    FOR EACH ROW
EXECUTE FUNCTION check_single_active_position();

------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_employee_inserted_correctly()
    RETURNS trigger AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM employee_positions_history
        WHERE employee_id = NEW.id AND end_date IS NULL
    ) THEN
        RAISE EXCEPTION 'Employee must have a current position';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_check_employee_position
    AFTER INSERT ON employees
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE FUNCTION check_employee_inserted_correctly();

CREATE OR REPLACE FUNCTION add_employee(
    _first_name VARCHAR(30),
    _last_name VARCHAR(30),
    _second_name VARCHAR(30),
    _gender CHAR(1),
    _phone VARCHAR(20),
    _email VARCHAR(100),
    _passport VARCHAR(20),
    _pesel CHAR(11),
    _address_id INTEGER,
    _correspondence_address_id INTEGER,
    _birth_date DATE,
    _position VARCHAR(30),
    _team_id INTEGER,
    _position_start_date DATE DEFAULT CURRENT_DATE,
    _team_start_date DATE DEFAULT CURRENT_DATE,
    _department_name VARCHAR(50) DEFAULT NULL,
    _department_start_date DATE DEFAULT NULL,
    _department_assign_start DATE DEFAULT CURRENT_DATE
) RETURNS VOID AS $$
DECLARE
    _employee_id INTEGER;
BEGIN
    INSERT INTO employees (
        first_name, last_name, second_name, gender,
        phone, email, passport, pesel,
        address_id, correspondence_address_id, birth_date
    )
    VALUES (
               _first_name, _last_name, _second_name, _gender,
               _phone, _email, _passport, _pesel,
               _address_id, _correspondence_address_id, _birth_date
           )
    RETURNING id INTO _employee_id;

    INSERT INTO employee_positions_history (
        employee_id, position, start_date
    ) VALUES (
                 _employee_id, _position, _position_start_date
             );

    IF _team_id IS NOT NULL THEN
        INSERT INTO employee_teams_history (
            employee_id, _team_id, start_date
        ) VALUES (
                     _employee_id, _team_id, _team_start_date
                 );
    END IF;

    IF (_department_name IS NULL AND _department_start_date IS NOT NULL) OR
       (_department_name IS NOT NULL AND _department_start_date IS NULL) THEN
        RAISE EXCEPTION '_department_name is "%" and _department_start_date is "%", should be 2 or 0 nulls', _department_name, _department_start_date;
    END IF;
    IF _department_name IS NOT NULL AND _department_start_date IS NOT NULL THEN
        INSERT INTO employee_departments_history (
            employee_id, department_name, department_start_date, start_date
        ) VALUES (
                     _employee_id, _department_name, _department_start_date, _department_assign_start
                 );
    END IF;
END;
$$ LANGUAGE plpgsql;


------------------------------------------------------------------------



CREATE OR REPLACE FUNCTION check_departments_consistency()
    RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.end_date IS NOT NULL THEN
        RAISE EXCEPTION 'we should not update departments history';
    END IF;

    IF NEW.end_date IS NOT NULL THEN
        IF TG_OP = 'UPDATE' AND OLD.end_date IS NULL THEN
            UPDATE head_departments_history
            SET end_date = NEW.end_date
            WHERE department_name = NEW.name
              AND department_start_date = NEW.start_date
              AND end_date IS NULL;

            UPDATE employee_departments_history
            SET end_date = NEW.end_date
            WHERE department_name = NEW.name
              AND department_start_date = NEW.start_date
              AND end_date IS NULL;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER departments_consistency_trigger
    BEFORE INSERT OR UPDATE ON departments
    FOR EACH ROW
EXECUTE FUNCTION check_departments_consistency();



-----------------------------------------------



CREATE OR REPLACE FUNCTION create_full_address(
    p_country_name VARCHAR,
    p_region_name  VARCHAR,
    p_city_name    VARCHAR,
    p_house       VARCHAR,
    p_street      VARCHAR DEFAULT NULL,
    p_postal_code VARCHAR DEFAULT NULL
) RETURNS INTEGER AS
$$
DECLARE
    v_country_name VARCHAR;
    v_region_id    INTEGER;
    v_city_id      INTEGER;
    v_address_id   INTEGER;
BEGIN
    INSERT INTO countries(name)
    VALUES (p_country_name)
    ON CONFLICT (name) DO NOTHING;
    v_country_name = p_country_name;

    SELECT id INTO v_region_id FROM regions
    WHERE country_name = v_country_name AND name = p_region_name;

    IF v_region_id IS NULL THEN
        INSERT INTO regions(country_name, name)
        VALUES (v_country_name, p_region_name)
        RETURNING id INTO v_region_id;
    END IF;

    SELECT id INTO v_city_id FROM cities
    WHERE region_id = v_region_id AND name = p_city_name;

    IF v_city_id IS NULL THEN
        INSERT INTO cities(region_id, name)
        VALUES (v_region_id, p_city_name)
        RETURNING id INTO v_city_id;
    END IF;

    SELECT id INTO v_address_id FROM addresses
    WHERE postal_code = p_postal_code
      AND COALESCE(street, '') = COALESCE(p_street, '')
      AND house = p_house
      AND city_id = v_city_id;

    IF v_address_id IS NULL THEN
        INSERT INTO addresses(house, street, city_id, postal_code)
        VALUES (p_house, p_street, v_city_id, p_postal_code)
        RETURNING id INTO v_address_id;
    END IF;

    RETURN v_address_id;
END;
$$ LANGUAGE plpgsql;



----------------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_head()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (
                SELECT 1 FROM head_departments_history
                WHERE department_name = NEW.department_name AND end_date IS NULL
            ) THEN
                RAISE EXCEPTION 'Active head already exists for department %', NEW.department_name;
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            IF (NEW.head_id, NEW.start_date) != (OLD.head_id, OLD.start_date) THEN
                IF EXISTS (
                    SELECT 1 FROM head_departments_history
                    WHERE department_name = NEW.department_name AND end_date IS NULL
                      AND (head_id, start_date) != (OLD.head_id, OLD.start_date)
                ) THEN
                    RAISE EXCEPTION 'Active head already exists for department %', NEW.department_name;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_unique_active_head
    BEFORE INSERT OR UPDATE ON head_departments_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_head();



--------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_position()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF TG_OP = 'INSERT'
            OR (TG_OP = 'UPDATE' AND (NEW.employee_id, NEW.start_date) != (OLD.employee_id, OLD.start_date)) THEN
            IF EXISTS (
                SELECT 1 FROM employee_positions_history
                WHERE employee_id = NEW.employee_id
                  AND end_date IS NULL
                  AND (TG_OP = 'INSERT' OR (employee_id, start_date) != (OLD.employee_id, OLD.start_date))
            ) THEN
                RAISE EXCEPTION 'Employee % already has an active position record', NEW.employee_id;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_unique_active_position
    BEFORE INSERT OR UPDATE ON employee_positions_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_position();


--------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_department()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (
                SELECT 1 FROM employee_departments_history
                WHERE employee_id = NEW.employee_id AND end_date IS NULL
            ) THEN
                RAISE EXCEPTION 'Employee % already assigned to an active department', NEW.employee_id;
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            IF (NEW.department_name, NEW.department_start_date, NEW.start_date) !=
               (OLD.department_name, OLD.department_start_date, OLD.start_date) THEN
                IF EXISTS (
                    SELECT 1 FROM employee_departments_history
                    WHERE employee_id = NEW.employee_id AND end_date IS NULL
                      AND (department_name, department_start_date, start_date) !=
                          (OLD.department_name, OLD.department_start_date, OLD.start_date)
                ) THEN
                    RAISE EXCEPTION 'Employee % already assigned to an active department', NEW.employee_id;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_unique_active_department
    BEFORE INSERT OR UPDATE ON employee_departments_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_department();


--------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_team()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.leave_ts IS NULL THEN
        IF TG_OP = 'INSERT'
            OR (TG_OP = 'UPDATE' AND (NEW.employee_id, NEW.join_ts) != (OLD.employee_id, OLD.join_ts)) THEN
            IF EXISTS (
                SELECT 1 FROM employee_teams_history
                WHERE employee_id = NEW.employee_id
                  AND leave_ts IS NULL
                  AND (TG_OP = 'INSERT' OR (employee_id, join_ts) != (OLD.employee_id, OLD.join_ts))
            ) THEN
                RAISE EXCEPTION 'Employee % already has an active team assignment', NEW.employee_id;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_unique_active_team
    BEFORE INSERT OR UPDATE ON employee_teams_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_team();


-----------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_vacation()
    RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('requested', 'approved') THEN
        IF TG_OP = 'INSERT'
            OR (TG_OP = 'UPDATE' AND NEW.id != OLD.id) THEN
            IF EXISTS (
                SELECT 1 FROM vacations
                WHERE employee_id = NEW.employee_id
                  AND status IN ('requested', 'approved')
                  AND (
                    daterange(start_date, end_date, '[]') &&
                    daterange(NEW.start_date, NEW.end_date, '[]')
                    )
                  AND (TG_OP = 'INSERT' OR id != OLD.id)
            ) THEN
                RAISE EXCEPTION 'Employee % already has an active vacation overlapping [% - %]',
                    NEW.employee_id, NEW.start_date, NEW.end_date;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_unique_active_vacation
    BEFORE INSERT OR UPDATE ON vacations
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_vacation();

-----------------------------------------------------