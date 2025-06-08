import datetime
import random


def generate_employee_schedule_inserts(
        num_employees: int = 10,
        min_employee_id: int = 1,
        max_employee_id: int = 100,  # Max possible employee ID to pick from
        start_year_range: tuple = (2022, 2024),
        max_schedule_duration_years: int = 3,
        max_shifts_per_employee: int = 5  # Max different schedule patterns per employee
) -> str:
    """
    Generates SQL INSERT statements for the 'employee_schedule' table.

    Args:
        num_employees (int): The number of unique employee_ids to generate schedules for.
        min_employee_id (int): The minimum possible employee ID to use.
        max_employee_id (int): The maximum possible employee ID to use.
        start_year_range (tuple): A tuple (start_year, end_year) for the possible
                                  start_date of schedules.
        max_schedule_duration_years (int): Maximum duration for a single schedule period
                                           (before an end_date, if not NULL).
        max_shifts_per_employee (int): Maximum number of distinct schedule patterns
                                       (e.g., Mon-Fri 9-5, then another Tue-Thu 10-2)
                                       an employee might have over time.

    Returns:
        str: A string containing all the generated SQL INSERT statements.
    """

    sql_statements = ["BEGIN;"]
    # Ensure unique employee IDs are selected from the available range
    employee_ids = random.sample(range(min_employee_id, max_employee_id + 1),
                                 min(num_employees, (max_employee_id - min_employee_id + 1)))

    current_date = datetime.date.today()

    for employee_id in employee_ids:
        # Each employee can have 1 to max_shifts_per_employee distinct schedule patterns
        num_schedule_patterns = random.randint(1, max_shifts_per_employee)

        last_schedule_end_date = None  # Tracks the end date of the previous schedule for this employee

        for i in range(num_schedule_patterns):  # Use 'i' for index to break loop if needed
            # Generate a random start_date for the schedule pattern
            year = random.randint(start_year_range[0], start_year_range[1])
            month = random.randint(1, 12)
            day = random.randint(1, 28)  # To avoid issues with 31-day months
            candidate_schedule_start_date = datetime.date(year, month, day)

            # Ensure the current schedule_start_date is strictly after the previous schedule's end_date
            if last_schedule_end_date:
                # If there was a previous schedule, this one should start 1-30 days after the last one ended.
                schedule_start_date = last_schedule_end_date + datetime.timedelta(days=random.randint(1, 30))
                # If this calculated start_date is too far in future, stop generating more patterns for this employee
                if schedule_start_date > current_date + datetime.timedelta(days=365):
                    break  # Break inner loop, move to next employee
            else:
                schedule_start_date = candidate_schedule_start_date

            # Ensure schedule_start_date isn't in the distant future beyond current_date + 1 year
            if schedule_start_date > current_date + datetime.timedelta(days=365):
                # If even the initial random start date is too far, make it current or slightly future
                schedule_start_date = current_date + datetime.timedelta(days=random.randint(0, 30))

            # If the calculated schedule_start_date is before the very first specified start year, adjust it.
            if schedule_start_date.year < start_year_range[0]:
                schedule_start_date = datetime.date(start_year_range[0], 1, 1) + datetime.timedelta(
                    days=random.randint(0, 364))

            # Randomly decide if there's an end_date (approx 70% chance of being NULL for long-term)
            schedule_end_date_str = "NULL"
            is_last_pattern = (i == num_schedule_patterns - 1)

            if random.random() < 0.7 and not is_last_pattern:  # 70% chance of a defined end_date for non-last patterns
                delta_days = random.randint(30, max_schedule_duration_years * 365)
                end_date_obj = schedule_start_date + datetime.timedelta(days=delta_days)

                # Cap end_date at current_date if it goes too far into the future
                if end_date_obj > current_date + datetime.timedelta(days=30):
                    end_date_obj = current_date + datetime.timedelta(days=random.randint(0, 30))

                # CRITICAL: Ensure start_date <= end_date for the current row.
                if end_date_obj < schedule_start_date:
                    schedule_end_date_str = "NULL"  # Cannot have end before start, so make it ongoing
                else:
                    schedule_end_date_str = f"'{end_date_obj.isoformat()}'"
            elif is_last_pattern and schedule_start_date <= current_date:
                # If it's the last pattern and starts in the past/present, it's typically ongoing (NULL)
                # unless explicitly given an end date that is <= current_date.
                if random.random() < 0.2:  # Small chance the last one also has an end date
                    end_date_obj = schedule_start_date + datetime.timedelta(days=random.randint(30, 365))
                    if end_date_obj > current_date:
                        end_date_obj = current_date
                    if end_date_obj >= schedule_start_date:
                        schedule_end_date_str = f"'{end_date_obj.isoformat()}'"
                    else:
                        schedule_end_date_str = "NULL"
                else:
                    schedule_end_date_str = "NULL"
            else:
                # If the last pattern starts in the future, it's ongoing
                schedule_end_date_str = "NULL"

            # Determine the weekdays for this schedule pattern
            schedule_type = random.choice(['full_week', 'weekdays', 'random_days'])
            if schedule_type == 'full_week':
                weekdays = list(range(1, 8))
            elif schedule_type == 'weekdays':
                weekdays = list(range(1, 6))
            else:  # random_days
                weekdays = random.sample(range(1, 8), random.randint(1, 4))  # 1 to 4 random days

            # Generate sensible working hours for these weekdays
            for weekday in weekdays:
                # Random start time between 8 AM and 10 AM
                start_hour = random.randint(8, 10)
                start_minute = random.choice([0, 15, 30, 45])
                start_time_obj = datetime.time(start_hour, start_minute)

                # Random duration between 4 and 9 hours
                duration_hours = random.randint(4, 9)
                duration_minutes = random.choice([0, 15, 30, 45])
                end_time_total_minutes = (start_hour * 60 + start_minute) + (duration_hours * 60 + duration_minutes)

                end_hour = (end_time_total_minutes // 60) % 24
                end_minute = end_time_total_minutes % 60
                end_time_obj = datetime.time(end_hour, end_minute)

                # Simple check to ensure end_time is after start_time if within the same day
                if end_time_obj <= start_time_obj:
                    end_time_obj = (datetime.datetime.combine(datetime.date.min, start_time_obj) + datetime.timedelta(
                        hours=8)).time()

                insert_statement = (
                    f"INSERT INTO employee_schedule (employee_id, weekday, start_time, end_time, start_date, end_date) VALUES "
                    f"({employee_id}, {weekday}, '{start_time_obj.strftime('%H:%M:%S')}', "
                    f"'{end_time_obj.strftime('%H:%M:%S')}', '{schedule_start_date.isoformat()}', {schedule_end_date_str});"
                )
                sql_statements.append(insert_statement)

            # Update last_schedule_end_date after all days for the current pattern are processed
            if schedule_end_date_str != "NULL":
                last_schedule_end_date = datetime.date.fromisoformat(schedule_end_date_str.strip("'"))
            else:
                # If the current schedule pattern is ongoing (NULL end_date),
                # it implies it's the most current or future one.
                # We typically wouldn't generate *further* historical patterns for this employee after an ongoing one.
                break  # Stop generating more patterns for this employee if the current one is ongoing

    sql_statements.append("COMMIT;")
    return "\n".join(sql_statements)


def generate_employer_salary_inserts(
        num_employees: int = 10,
        min_employee_id: int = 1,
        max_employee_id: int = 100,
        start_year_range: tuple = (2020, 2024),
        salary_range: tuple = (50000, 150000),  # Min and max annual salary
        max_salary_changes_per_employee: int = 5
) -> str:
    """
    Generates SQL INSERT statements for the 'employer_salary' table.

    Args:
        num_employees (int): The number of unique employee_ids to generate salary entries for.
        min_employee_id (int): The minimum possible employee ID to use.
        max_employee_id (int): The maximum possible employee ID to use.
        start_year_range (tuple): A tuple (start_year, end_year) for the possible
                                  start_date of the first salary entry for an employee.
        salary_range (tuple): A tuple (min_salary, max_salary) for the annual salary.
        max_salary_changes_per_employee (int): Maximum number of distinct salary entries
                                               (e.g., initial salary, then a raise)
                                               an employee might have over time.

    Returns:
        str: A string containing all the generated SQL INSERT statements.
    """

    sql_statements = ["BEGIN;"]
    # Ensure unique employee IDs are selected from the available range
    employee_ids = random.sample(range(min_employee_id, max_employee_id + 1),
                                 min(num_employees, (max_employee_id - min_employee_id + 1)))

    current_date = datetime.date.today()

    for employee_id in employee_ids:
        # Determine the number of salary changes for this employee
        num_salary_entries = random.randint(1, max_salary_changes_per_employee)

        # Generate the first start_date for this employee's salary history
        first_year = random.randint(start_year_range[0], start_year_range[1])
        first_month = random.randint(1, 12)
        first_day = random.randint(1, 28)  # To avoid issues with 31-day months
        current_salary_start_date = datetime.date(first_year, first_month, first_day)

        # Ensure the first start_date isn't in the distant future.
        # It should be at most current_date + 30 days.
        if current_salary_start_date > current_date + datetime.timedelta(days=30):
            current_salary_start_date = current_date - datetime.timedelta(
                days=random.randint(0, 365))  # Backdate slightly if too far future

        # Generate an initial salary
        current_salary = random.randint(salary_range[0] // 1000,
                                        salary_range[1] // 1000) * 1000  # Round to nearest 1000

        for i in range(num_salary_entries):
            salary_end_date_str = "NULL"  # Default to NULL (ongoing) for the current period

            # Determine the end_date for the *current* salary entry
            # and the start_date for the *next* one (if applicable).
            if i < num_salary_entries - 1:  # If this is not the last salary entry for the employee
                # Calculate the start date for the *next* salary entry
                # This helps determine the end date of the *current* salary entry
                next_start_offset_days = random.randint(90, 365 * 2)  # Next salary starts 3 months to 2 years later
                next_salary_start_date_candidate = current_salary_start_date + datetime.timedelta(
                    days=next_start_offset_days)

                # Cap the end date of the current period if the next start date would be in the far future
                if next_salary_start_date_candidate > current_date + datetime.timedelta(days=30):
                    # If the next salary would start too far in the future,
                    # this current salary is the latest effective one and should be ongoing (NULL).
                    # We also stop generating further entries for this employee.
                    salary_end_date_str = "NULL"
                    num_salary_entries = i + 1  # Effectively end the loop
                else:
                    # The end date for the *current* salary period is one day before the next one starts
                    end_date_for_current_entry = next_salary_start_date_candidate - datetime.timedelta(days=1)

                    # Ensure this end_date is not after the current system date.
                    if end_date_for_current_entry > current_date:
                        end_date_for_current_entry = current_date

                    # CRITICAL: Ensure start_date <= end_date for the *current* row.
                    if end_date_for_current_entry < current_salary_start_date:
                        # This should ideally not happen with the controlled progression,
                        # but as a safeguard, make it NULL if invalid.
                        salary_end_date_str = "NULL"
                    else:
                        salary_end_date_str = f"'{end_date_for_current_entry.isoformat()}'"
            else:
                # If this is the last salary entry, it should generally be ongoing (NULL)
                # unless its start_date is in the distant past (e.g., more than 5 years ago)
                # AND it was randomly decided to have an end date to reflect historical data.
                # If it's the last one, and starts in the past/present, it's typically ongoing.
                if current_salary_start_date <= current_date and random.random() < 0.2:  # Small chance the very last one also ended
                    end_date_obj = current_salary_start_date + datetime.timedelta(days=random.randint(30, 365))
                    if end_date_obj > current_date:
                        end_date_obj = current_date
                    if end_date_obj >= current_salary_start_date:
                        salary_end_date_str = f"'{end_date_obj.isoformat()}'"
                    else:
                        salary_end_date_str = "NULL"  # Fallback
                elif current_salary_start_date > current_date:
                    # If the *last* salary entry starts in the future, it must be ongoing.
                    salary_end_date_str = "NULL"
                else:
                    # Default for a past/current last entry: ongoing
                    salary_end_date_str = "NULL"

            insert_statement = (
                f"INSERT INTO employer_salary (employee_id, salary, start_date, end_date) VALUES "
                f"({employee_id}, {current_salary}, '{current_salary_start_date.isoformat()}', {salary_end_date_str});"
            )
            sql_statements.append(insert_statement)

            # Update current_salary_start_date for the next iteration
            if salary_end_date_str != "NULL":
                current_salary_start_date = datetime.date.fromisoformat(
                    salary_end_date_str.strip("'")) + datetime.timedelta(days=1)
                # If the next start date is already significantly in the future, stop generating for this employee
                if current_salary_start_date > current_date + datetime.timedelta(days=30):
                    break
            else:  # If the current salary was ongoing (end_date NULL), no more future entries for this employee based on this path
                break

            # Simulate a raise or change for the next period
            # Ensure salary stays within the defined range
            current_salary = max(salary_range[0], min(salary_range[1], current_salary + random.randint(-5000, 15000)))
            current_salary = (current_salary // 1000) * 1000  # Keep it rounded to nearest 1000

    sql_statements.append("COMMIT;")
    return "\n".join(sql_statements)


# --- How to use the generator ---
if __name__ == "__main__":
    # Example usage:
    # Ensure your database is empty or can handle these inserts without constraint violations
    # or consider using ON CONFLICT clauses if your database supports it and you intend to upsert.

    print("--Generating schedule entries for 100 employees (example smaller set):")
    inserts_for_100_employees_schedule = generate_employee_schedule_inserts(num_employees=100)
    # print(inserts_for_100_employees_schedule)
    with open("employee_schedule_inserts.sql", "w") as f:
        f.write(inserts_for_100_employees_schedule)
    print("Generated employee_schedule_inserts.sql")

    print("\n" + "=" * 50 + "\n")

    print("--Generating salary entries for 100 employees (example smaller set):")
    inserts_for_100_employees_salary = generate_employer_salary_inserts(num_employees=100)
    # print(inserts_for_100_employees_salary)
    with open("employer_salary_inserts.sql", "w") as f:
        f.write(inserts_for_100_employees_salary)
    print("Generated employer_salary_inserts.sql")