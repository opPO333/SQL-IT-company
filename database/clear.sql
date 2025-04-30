DROP TYPE IF EXISTS equipment_type CASCADE;
DROP TYPE IF EXISTS equipment_status CASCADE;

DROP TABLE IF EXISTS
    schedule_exceptions,
    position_schedules,
    employee_days,
    employee_positions_history,
    vacations,
    employee_teams_history,
    employee_departments_history,
    tasks,
    equipment,
    teams,
    departments,
    projects,
    employees,
    positions,
    addresses
CASCADE;