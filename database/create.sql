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
CREATE INDEX idx_addresses_postal_street ON addresses (postal_code, street);
CREATE INDEX idx_regions_country_and_name ON regions (country_name, name);
CREATE INDEX idx_cities_region_and_name ON cities (region_id, name);

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
    position VARCHAR(30) PRIMARY KEY
);

CREATE TABLE employee_schedule
(
    employee_id INTEGER REFERENCES employees (id) ON DELETE RESTRICT NOT NULL,
    weekday     INTEGER                                              NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    start_time  TIME                                                 NOT NULL,
    end_time    TIME                                                 NOT NULL,
    start_date  DATE                                                 NOT NULL,
    end_date    DATE,

    PRIMARY KEY (employee_id, weekday, start_date, start_time),
    CHECK ( end_date IS NULL OR start_date <= end_date )
);

CREATE TABLE employee_salary
(
    employee_id INTEGER NOT NULL REFERENCES employees (id),
    salary      INTEGER NOT NULL,
    start_date  DATE    NOT NULL,
    end_date    DATE,

    PRIMARY KEY (employee_id, start_date),
    CHECK ( end_date IS NULL OR start_date <= end_date )
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
    end_date     DATE             DEFAULT NULL,

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

CREATE OR REPLACE VIEW teams_view AS
SELECT t.id, t.start_date, p.title as project_title
FROM teams t
         LEFT JOIN projects p on p.title = t.project_title
WHERE t.end_date IS NULL;


------------------------------------------------------------------------

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
SELECT e.id,
       e.first_name,
       e.last_name,
       e.second_name,
       e.gender,
       e.phone,
       e.pesel,
       e.passport,
       e.email,
       e.birth_date,
       edh.department_name,
       edh.department_start_date,
       eth.team_id,
       p.position as position_name,
       es.salary,
       ca.street  as correspondence_street,
       ca.house   as correspondence_house,
       ca.city_id as correspondence_city_id,
       ca.postal_code as correspondence_postal_code,
       a.street  as street,
       a.house   as house,
       a.city_id as city_id,
       a.postal_code as postal_code
FROM employees e
         JOIN employee_departments_history edh
              ON e.id = edh.employee_id
                  AND edh.end_date IS NULL
         LEFT JOIN employee_teams_history eth on e.id = eth.employee_id
         JOIN employee_positions_history eph on e.id = eph.employee_id and eph.end_date IS NULL
         JOIN positions p on eph.position = p.position
         JOIN employee_salary es on e.id = es.employee_id AND es.end_date IS NULL
         JOIN addresses ca on e.correspondence_address_id = ca.id
         LEFT JOIN addresses a ON e.address_id = a.id;


CREATE VIEW departments_view AS
SELECT d.*, e.id as head_id
FROM departments d
         LEFT JOIN head_departments_history hdh
                   ON d.name = hdh.department_name AND d.start_date = hdh.department_start_date
         LEFT JOIN employees e on hdh.head_id = e.id
WHERE d.end_date IS NULL;


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


------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_and_close_position() RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS (SELECT 1
               FROM employee_positions_history eph
               WHERE eph.employee_id = NEW.employee_id
                 AND (TG_OP != 'UPDATE' OR eph.start_date != OLD.start_date)
                 AND GREATEST(NEW.start_date, eph.start_date) < LEAST(
                       COALESCE(NEW.end_date, DATE '9999-12-31'),
                       COALESCE(eph.end_date, CURRENT_DATE)
                                                                )) THEN
        RAISE EXCEPTION 'Overlapping position period for employee %', NEW.employee_id;
    END IF;

    IF NEW.end_date IS NULL THEN
        UPDATE employee_positions_history
        SET end_date = NEW.start_date
        WHERE employee_id = NEW.employee_id
          AND end_date IS NULL
          AND start_date < NEW.start_date;
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


CREATE OR REPLACE FUNCTION check_employee_inserted_correctly()
    RETURNS trigger AS
$$
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM employee_positions_history
                   WHERE employee_id = NEW.id
                     AND end_date IS NULL) THEN
        RAISE EXCEPTION 'Employee must have a current position';
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_check_employee_position
    AFTER INSERT
    ON employees
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
    _correspondence_address_id INTEGER,
    _birth_date DATE,
    _position VARCHAR(30),
    _team_id INTEGER,
    _salary INTEGER,
    _address_id INTEGER DEFAULT NULL,
    _position_start_date DATE DEFAULT CURRENT_DATE,
    _team_start_date DATE DEFAULT CURRENT_DATE,
    _department_name VARCHAR(50) DEFAULT NULL,
    _department_start_date DATE DEFAULT NULL,
    _department_assign_start DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS
$$
DECLARE
    _employee_id INTEGER;
BEGIN
    INSERT INTO employees (first_name, last_name, second_name, gender,
                           phone, email, passport, pesel,
                           address_id, correspondence_address_id, birth_date)
    VALUES (_first_name, _last_name, _second_name, _gender,
            _phone, _email, _passport, _pesel,
            _address_id, _correspondence_address_id, _birth_date)
    RETURNING id INTO _employee_id;

    INSERT INTO employee_positions_history (employee_id, position, start_date)
    VALUES (_employee_id, _position, _position_start_date);

    IF _salary IS NOT NULL THEN
        INSERT INTO employee_salary (employee_id, salary, start_date)
        VALUES (_employee_id, _salary, CURRENT_DATE);
    END IF;


    IF _team_id IS NOT NULL THEN
        INSERT INTO employee_teams_history (employee_id, team_id, join_ts)
        VALUES (_employee_id, _team_id, _team_start_date);
    END IF;

    IF (_department_name IS NULL AND _department_start_date IS NOT NULL) OR
       (_department_name IS NOT NULL AND _department_start_date IS NULL) THEN
        RAISE EXCEPTION '_department_name is "%" and _department_start_date is "%", should be 2 or 0 nulls', _department_name, _department_start_date;
    END IF;
    IF _department_name IS NOT NULL AND _department_start_date IS NOT NULL THEN
        INSERT INTO employee_departments_history (employee_id, department_name, department_start_date, start_date)
        VALUES (_employee_id, _department_name, _department_start_date, _department_assign_start);
    END IF;
    RETURN _employee_id;
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
    BEFORE INSERT OR UPDATE
    ON departments
    FOR EACH ROW
EXECUTE FUNCTION check_departments_consistency();


-----------------------------------------------


CREATE OR REPLACE FUNCTION create_full_address(
    p_country_name VARCHAR,
    p_region_name VARCHAR,
    p_city_name VARCHAR,
    p_house VARCHAR,
    p_street VARCHAR DEFAULT NULL,
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

    SELECT id
    INTO v_region_id
    FROM regions
    WHERE country_name = v_country_name
      AND name = p_region_name;

    IF v_region_id IS NULL THEN
        INSERT INTO regions(country_name, name)
        VALUES (v_country_name, p_region_name)
        RETURNING id INTO v_region_id;
    END IF;

    SELECT id
    INTO v_city_id
    FROM cities
    WHERE region_id = v_region_id
      AND name = p_city_name;

    IF v_city_id IS NULL THEN
        INSERT INTO cities(region_id, name)
        VALUES (v_region_id, p_city_name)
        RETURNING id INTO v_city_id;
    END IF;

    SELECT id
    INTO v_address_id
    FROM addresses
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
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (SELECT 1
                       FROM head_departments_history
                       WHERE department_name = NEW.department_name
                         AND end_date IS NULL) THEN
                RAISE EXCEPTION 'Active head already exists for department %', NEW.department_name;
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            IF (NEW.head_id, NEW.start_date) != (OLD.head_id, OLD.start_date) THEN
                IF EXISTS (SELECT 1
                           FROM head_departments_history
                           WHERE department_name = NEW.department_name
                             AND end_date IS NULL
                             AND (head_id, start_date) != (OLD.head_id, OLD.start_date)) THEN
                    RAISE EXCEPTION 'Active head already exists for department %', NEW.department_name;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_unique_active_head
    BEFORE INSERT OR UPDATE
    ON head_departments_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_head();


--------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_position()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (
                SELECT 1 FROM employee_positions_history
                WHERE employee_id = NEW.employee_id
                  AND end_date IS NULL
            ) THEN
                RAISE EXCEPTION 'Employee % already has an active position record', NEW.employee_id;
            END IF;

        ELSIF TG_OP = 'UPDATE' THEN
            IF (NEW.employee_id, NEW.start_date) != (OLD.employee_id, OLD.start_date) THEN
                IF EXISTS (
                    SELECT 1 FROM employee_positions_history
                    WHERE employee_id = NEW.employee_id
                      AND end_date IS NULL
                      AND (employee_id, start_date) != (OLD.employee_id, OLD.start_date)
                ) THEN
                    RAISE EXCEPTION 'Employee % already has an active position record', NEW.employee_id;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_department()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.end_date IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (SELECT 1
                       FROM employee_departments_history
                       WHERE employee_id = NEW.employee_id
                         AND end_date IS NULL) THEN
                RAISE EXCEPTION 'Employee % already assigned to an active department', NEW.employee_id;
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            IF (NEW.department_name, NEW.department_start_date, NEW.start_date) !=
               (OLD.department_name, OLD.department_start_date, OLD.start_date) THEN
                IF EXISTS (SELECT 1
                           FROM employee_departments_history
                           WHERE employee_id = NEW.employee_id
                             AND end_date IS NULL
                             AND (department_name, department_start_date, start_date) !=
                                 (OLD.department_name, OLD.department_start_date, OLD.start_date)) THEN
                    RAISE EXCEPTION 'Employee % already assigned to an active department', NEW.employee_id;
                END IF;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_unique_active_department
    BEFORE INSERT OR UPDATE
    ON employee_departments_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_department();


--------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_team()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.leave_ts IS NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (SELECT 1
                       FROM employee_teams_history
                       WHERE employee_id = NEW.employee_id
                         AND leave_ts IS NULL) THEN
                RAISE EXCEPTION 'Employee % already has an active team assignment', NEW.employee_id;
            END IF;

        ELSIF TG_OP = 'UPDATE' THEN
            IF (NEW.employee_id, NEW.join_ts) != (OLD.employee_id, OLD.join_ts) THEN
                IF EXISTS (SELECT 1
                           FROM employee_teams_history
                           WHERE employee_id = NEW.employee_id
                             AND leave_ts IS NULL
                             AND NOT (employee_id = OLD.employee_id AND join_ts = OLD.join_ts)) THEN
                    RAISE EXCEPTION 'Employee % already has an active team assignment', NEW.employee_id;
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_unique_active_team
    BEFORE INSERT OR UPDATE
    ON employee_teams_history
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_team();


-----------------------------------------------------


CREATE OR REPLACE FUNCTION check_unique_active_vacation()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.status IN ('requested', 'approved') THEN
        IF TG_OP = 'INSERT' THEN
            IF EXISTS (
                SELECT 1 FROM vacations
                WHERE employee_id = NEW.employee_id
                  AND status IN ('requested', 'approved')
                  AND daterange(start_date, end_date, '[]') &&
                      daterange(NEW.start_date, NEW.end_date, '[]')
            ) THEN
                RAISE EXCEPTION 'Employee % already has an active vacation overlapping [% - %]',
                    NEW.employee_id, NEW.start_date, NEW.end_date;
            END IF;

        ELSIF TG_OP = 'UPDATE' THEN
            IF EXISTS (
                SELECT 1 FROM vacations
                WHERE employee_id = NEW.employee_id
                  AND status IN ('requested', 'approved')
                  AND daterange(start_date, end_date, '[]') &&
                      daterange(NEW.start_date, NEW.end_date, '[]')
                  AND id != NEW.id
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
    BEFORE INSERT OR UPDATE
    ON vacations
    FOR EACH ROW
EXECUTE FUNCTION check_unique_active_vacation();

CREATE OR REPLACE FUNCTION manage_equipment_status() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.end_date IS NULL THEN
        UPDATE equipment_status_history
        SET end_date = NEW.start_date
        WHERE equipment_id = NEW.equipment_id AND end_date IS NULL;

        INSERT INTO equipment_status_history(equipment_id, status, start_date)
        VALUES (NEW.equipment_id, 'assigned', NEW.start_date);

    ELSIF OLD.end_date IS NULL AND NEW.end_date IS NOT NULL THEN
        UPDATE equipment_status_history
        SET end_date = NEW.end_date
        WHERE equipment_id = NEW.equipment_id AND status = 'assigned' AND end_date IS NULL;

        INSERT INTO equipment_status_history(equipment_id, status, start_date)
        VALUES (NEW.equipment_id, 'in_stock', NEW.end_date);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_manage_equipment_status
AFTER INSERT OR UPDATE ON employee_equipment_history
FOR EACH ROW EXECUTE FUNCTION manage_equipment_status();

CREATE OR REPLACE FUNCTION check_vacation_self_approval() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.approved_by IS NOT NULL AND NEW.employee_id = NEW.approved_by THEN
        RAISE EXCEPTION 'Employee cannot approve their own vacation request.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_vacation_self_approval
BEFORE INSERT OR UPDATE ON vacations
FOR EACH ROW EXECUTE FUNCTION check_vacation_self_approval();

CREATE OR REPLACE FUNCTION fire_employee(eid INTEGER, fire_date DATE DEFAULT CURRENT_DATE)
RETURNS VOID AS $$
BEGIN
    UPDATE employee_positions_history
    SET end_date = fire_date
    WHERE employee_id = eid AND end_date IS NULL;

    UPDATE employee_departments_history
    SET end_date = fire_date
    WHERE employee_id = eid AND end_date IS NULL;

    UPDATE employee_salary
    SET end_date = fire_date
    WHERE employee_id = eid AND end_date IS NULL;

    UPDATE employee_teams_history
    SET leave_ts = fire_date::TIMESTAMP
    WHERE employee_id = eid AND leave_ts IS NULL;

    UPDATE employee_equipment_history
    SET end_date = fire_date
    WHERE employee_id = eid AND end_date IS NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_employee_salary_history(eid INTEGER)
RETURNS TABLE (
    salary INTEGER,
    start_date DATE,
    end_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT es.salary, es.start_date, es.end_date
    FROM employee_salary es
    WHERE es.employee_id = eid
    ORDER BY es.start_date DESC;
END;
$$ LANGUAGE plpgsql;

-- 1) A trigger‐wrapper that sees NEW, calls your routine, then returns NULL
CREATE OR REPLACE FUNCTION employees_view_insert_tr()
    RETURNS trigger
    LANGUAGE plpgsql AS
$$
DECLARE
        v_correspondence_address_id INT;
BEGIN
    SELECT id INTO v_correspondence_address_id
    FROM addresses
    WHERE city_id = NEW.correspondence_city_id AND
          street = NEW.correspondence_street AND
          house = NEW.correspondence_house AND
          postal_code = NEW.correspondence_postal_code;

    IF v_correspondence_address_id IS NULL THEN
        INSERT INTO addresses (city_id, street, house, postal_code)
        VALUES (NEW.correspondence_city_id, NEW.correspondence_street, NEW.correspondence_house, NEW.correspondence_postal_code)
        RETURNING id INTO v_correspondence_address_id;
    END IF;
    NEW.id := add_employee(
            NEW.first_name,
            NEW.last_name,
            NEW.second_name,
            NEW.gender,
            NEW.phone,
            NEW.email,
            NEW.passport,
            NEW.pesel,
            v_correspondence_address_id,
            NEW.birth_date,
            NEW.position_name,
            NEW.team_id,
            NEW.salary
            );
    RETURN NEW;
END;
$$;

CREATE TRIGGER employee_insert
    INSTEAD OF INSERT
    ON employees_view
    FOR EACH ROW
EXECUTE FUNCTION employees_view_insert_tr();

CREATE OR REPLACE FUNCTION prevent_deleting_active_position() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM employee_positions_history WHERE position = OLD.position AND end_date IS NULL) THEN
        RAISE EXCEPTION 'Cannot delete position "%" because it is currently assigned to one or more employees.', OLD.position;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_deleting_active_position
BEFORE DELETE ON positions
FOR EACH ROW EXECUTE FUNCTION prevent_deleting_active_position();

CREATE OR REPLACE FUNCTION prevent_deleting_active_project() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM teams WHERE project_title = OLD.title AND end_date IS NULL) THEN
        RAISE EXCEPTION 'Cannot delete project "%" because it is assigned to one or more active teams.', OLD.title;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_deleting_active_project
BEFORE DELETE ON projects
FOR EACH ROW EXECUTE FUNCTION prevent_deleting_active_project();

-----------------------------------------------------

CREATE OR REPLACE FUNCTION trg_employees_view_update()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$$
DECLARE
    now_ts TIMESTAMP := clock_timestamp();
BEGIN
    UPDATE employees
    SET first_name                = COALESCE(NEW.first_name, OLD.first_name)
      , second_name               = COALESCE(NEW.second_name, OLD.second_name)
      , last_name                 = COALESCE(NEW.last_name, OLD.last_name)
      , gender                    = COALESCE(NEW.gender, OLD.gender)
      , phone                     = COALESCE(NEW.phone, OLD.phone)
      , email                     = COALESCE(NEW.email, OLD.email)
      , pesel                     = COALESCE(NEW.pesel, OLD.pesel)
      , passport                  = COALESCE(NEW.passport, OLD.passport)
      , birth_date                = COALESCE(NEW.birth_date, OLD.birth_date)
      , correspondence_address_id = COALESCE(NEW.correspondence_address_id, OLD.correspondence_address_id)
    WHERE id = OLD.id;

    -- 3. Department‐change history
    IF (NEW.department_name IS NOT NULL AND NEW.department_name <> OLD.department_name)
        OR (NEW.department_start_date IS NOT NULL AND NEW.department_start_date <> OLD.department_start_date)
    THEN
        UPDATE employee_departments_history
        SET end_date = now_ts
        WHERE employee_id = OLD.id
          AND end_date IS NULL;

        INSERT INTO employee_departments_history(employee_id, department_name, department_start_date, start_date)
        VALUES (OLD.id, NEW.department_name, NEW.department_start_date, now_ts);
    END IF;

    -- 4. Team‐change history
    IF NEW.team_id IS NOT NULL AND NEW.team_id <> OLD.team_id THEN
        UPDATE employee_teams_history
        SET leave_ts = now_ts
        WHERE employee_id = OLD.id
          AND leave_ts IS NULL;

        INSERT INTO employee_teams_history(employee_id, team_id, join_ts)
        VALUES (OLD.id, NEW.team_id, now_ts);
    END IF;

    -- 5. Position‐change history
    IF NEW.position_name IS NOT NULL AND NEW.position_name <> OLD.position_name THEN
        UPDATE employee_positions_history
        SET end_date = now_ts
        WHERE employee_id = OLD.id
          AND end_date IS NULL;

        INSERT INTO employee_positions_history(employee_id, position, start_date)
        VALUES (OLD.id, NEW.position_name, now_ts);
    END IF;
    -- 6. Salary history
    IF NEW.salary IS NOT NULL AND NEW.salary <> OLD.salary THEN
        UPDATE employee_salary
        SET end_date = CURRENT_DATE
        WHERE employee_id = OLD.id
          AND end_date IS NULL;

        INSERT INTO employee_salary(employee_id, salary, start_date, end_date)
        VALUES (OLD.id, NEW.salary, CURRENT_DATE, NULL);
    end if;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_employees_view_update
    INSTEAD OF UPDATE
    ON employees_view
    FOR EACH ROW
EXECUTE FUNCTION trg_employees_view_update();

CREATE VIEW employee_departments_history_view AS
SELECT edh.employee_id,
       concat(e.first_name, ' ', e.last_name) as name,
       edh.department_name,
       edh.start_date,
       edh.end_date
FROM employees e
         JOIN employee_departments_history edh on e.id = edh.employee_id;

CREATE OR REPLACE FUNCTION manage_employees_view_delete()
    RETURNS TRIGGER AS
$$
BEGIN
    UPDATE employee_departments_history
    SET end_date = CURRENT_DATE
    WHERE employee_id = OLD.id
      AND end_date IS NULL;

    UPDATE employee_positions_history
    SET end_date = CURRENT_DATE
    WHERE employee_id = OLD.id
      AND end_date IS NULL;

    UPDATE employee_teams_history
    SET leave_ts = CURRENT_TIMESTAMP
    WHERE employee_id = OLD.id
      AND leave_ts IS NULL;

    UPDATE employee_salary
    SET end_date = CURRENT_DATE
    WHERE employee_id = OLD.id
      AND end_date IS NULL;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER instead_of_delete_on_employees_view
    INSTEAD OF DELETE
    ON employees_view
    FOR EACH ROW
EXECUTE FUNCTION manage_employees_view_delete();

