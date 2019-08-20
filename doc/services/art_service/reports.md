# ART Reports

## Cohort Report

* Can be accessed through `/programs/1/report/cohort` as either a `GET` or `POST`.
* Report is broken down into a bunch of indicators each of which must be accessed individually.
* Expected query string parameters are `start_date`, `end_date` (default: today), and `name`:
  - start_date, end_date: is the period the report must cover
  - name: refers to an indicator of the cohort report (see section [Cohort Report Indicators])
* In addition to the parameters above some indicators require a list of patient ids which should (and probably can) only be passed as POST parameters.
  - example:

  ```javascript
  await response = axios.post('/programs/1/reports/cohort?name=patients_with_side_effects&start_date=2019-01-01&2019-04-01', {
    extras: {
      patient_ids: [1, 2, 3, 4, 5] // This is a list of patient ids to restrict query to
    }
  });
  ```
* `NOTE`: Some indicators require a list of patient ids which should be passed through the extras parameter.

### Cohort Report Indicator

Below is a list of cohort report indicators. All indicators marked a * require an extra `patient_ids` argument as in the example in the previous section.

* `total_registered_patients`: Cummulative total registered patients
* `patients_reason_for_starting_art*`: Retrieve Reason for starting ART for each patient
* `patients_outcome*`: Retrieve patients outcome
* `patients_with_side_effects*`: Filter patients with TB in current period
* `patients_currently_with_tb*`: Filter patients with current episode of TB
* `patients_with_tb_in_last_2_years*`: Filter patients with TB within the last two years

