WITH OverallResults AS 
(
    SELECT L.firstname + ' ' + L.surname AS LearnerName,
           L.Apprentice_ULN,
           SAMRH.assessment_measurement_criteria_id measurementid,
           AMC.sub_code measurement_code,
           AMC.measurement measurement_description,
           SAMRH.evidence_review_result measurement_result,
           SAMRH.created_at result_created_at,
           SAMRH.phase measurement_phase,
           SAMRH.[version] measurement_version
    FROM SubmissionAssessment SA
    JOIN SubmissionAssessmentCriteriaHistory SACH
        ON SA.id = SACH.submission_assessment_id
    JOIN SubmissionAssessmentMeasurementResultsHistory SAMRH
        ON SACH.id = SAMRH.submission_assessment_criteria_id
    JOIN AssessmentMeasurementCriteria AMC
        ON SAMRH.assessment_measurement_criteria_id = AMC.id
    JOIN LearnerSubmission LS
        ON SA.learner_submission_id = LS.id
    JOIN Learner L
        ON LS.learner_id = L.id 
    WHERE LS.learner_id = 'd679d744-d9d9-47a6-acc8-d972dd2f765d'
    AND LS.submission_name NOT LIKE '%retry%'
),
MeasurementPhase0 AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY measurementid 
               ORDER BY measurement_version
           ) as version_rank
    FROM OverallResults
    WHERE measurement_phase = 0
),
MeasurementPhase4 AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY measurementid 
               ORDER BY measurement_version DESC
           ) as version_rank
    FROM OverallResults
    WHERE measurement_phase = 4
),
result_query AS (
SELECT DISTINCT
    mp0.LearnerName,
    mp0.Apprentice_ULN,
    mp0.measurement_code,
    mp0.measurement_description,
    mp0.measurement_version as phase0_measurement_version,
    mp0.measurement_result as phase0_measurement_result,
    mp0.result_created_at as phase0_measurement_date,
    mp4.measurement_version as phase4_measurement_version,
    mp4.measurement_result as phase4_measurement_result,
    mp4.result_created_at as phase4_measurement_date,
    CASE 
        WHEN mp0.measurement_result = mp4.measurement_result THEN 'True'
        ELSE 'False'
    END as measurement_results_match
FROM MeasurementPhase0 mp0
LEFT JOIN MeasurementPhase4 mp4
    ON mp0.measurementid = mp4.measurementid
    AND mp4.version_rank = 1
WHERE mp0.version_rank = 1
),
match_calculations AS (
    SELECT 
        LearnerName,
        Apprentice_ULN,
        COUNT(measurement_code) as total_measurements,
        SUM(CASE WHEN measurement_results_match = 'True' THEN 1 ELSE 0 END) as matching_measurements
    FROM result_query
    GROUP BY 
        LearnerName,
        Apprentice_ULN
)

SELECT 
    LearnerName,
    Apprentice_ULN,
    CAST(ROUND(
        (CAST(matching_measurements AS FLOAT) / NULLIF(total_measurements, 0)) * 100,
        2
    ) AS DECIMAL(5,2)) as measurement_match_percentage,
    matching_measurements,
    total_measurements
FROM match_calculations;