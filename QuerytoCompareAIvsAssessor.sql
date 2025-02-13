--- Query to compare AI generated results to assessor generated ones and getting a score on it
--- This query is used to compare the results of the AI generated results to the assessor generated results for one apprentice
-- Put them in list format: ('661baa7f-604c-4248-9cb4-9095e8918f27', '17fe04d9-689e-4758-a171-f25868a8006d', 'd679d744-d9d9-47a6-acc8-d972dd2f765d', '762ef0ee-f5af-441e-8b8e-ee15721f0d6b', '9c279464-f202-4f8d-99f7-06d27d859a3d')

WITH OverallResults AS 
(
    SELECT L.firstname + ' ' + L.surname AS LearnerName,
           L.Apprentice_ULN,
           LS.submission_name, 
           SACH.submission_assessment_id,
           SACH.assessment_grading_criteria_id CriteriaId,
           AGC.code CriteriaCode,
           AGC.[description] CriteriaDescription,
           SACH.result CriteriaResult,
           SACH.[version] CriteriaVersion,
           SACH.phase CriteriaPhase,
           SACH.created_at CriteriaCreatedAt,
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
    JOIN AssessmentGradingCriteria AGC
        ON SACH.assessment_grading_criteria_id = AGC.id
    JOIN SubmissionAssessmentMeasurementResultsHistory SAMRH
        ON SACH.id = SAMRH.submission_assessment_criteria_id
    JOIN AssessmentMeasurementCriteria AMC
        ON SAMRH.assessment_measurement_criteria_id = AMC.id
    JOIN LearnerSubmission LS
        ON SA.learner_submission_id = LS.id
    JOIN Learner L
        ON LS.learner_id = L.id 
    WHERE LS.learner_id = '9c279464-f202-4f8d-99f7-06d27d859a3d' 
    AND LS.submission_name NOT LIKE '%retry%'
),
CriteriaPhase0 AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY CriteriaId 
               ORDER BY CriteriaVersion
           ) as version_rank
    FROM OverallResults
    WHERE CriteriaPhase = 0
),
CriteriaPhase4 AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY CriteriaId 
               ORDER BY CriteriaVersion DESC
           ) as version_rank
    FROM OverallResults
    WHERE CriteriaPhase = 4
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
    cp0.LearnerName,
    cp0.Apprentice_ULN,
    cp0.submission_name,
    -- Criteria Information
    cp0.CriteriaCode,
    cp0.CriteriaDescription,
    cp0.CriteriaVersion as phase0_criteria_version,
    cp0.CriteriaResult as phase0_criteria_result,
    cp0.CriteriaCreatedAt as phase0_criteria_date,
    cp4.CriteriaVersion as phase4_criteria_version,
    cp4.CriteriaResult as phase4_criteria_result,
    cp4.CriteriaCreatedAt as phase4_criteria_date,
    CASE 
        WHEN cp0.CriteriaResult = cp4.CriteriaResult THEN 'True'
        ELSE 'False'
    END as criteria_results_match,
    -- Measurement Information
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
FROM CriteriaPhase0 cp0
LEFT JOIN CriteriaPhase4 cp4 
    ON cp0.CriteriaId = cp4.CriteriaId
    AND cp4.version_rank = 1
LEFT JOIN MeasurementPhase0 mp0
    ON cp0.CriteriaId = mp0.CriteriaId
    AND mp0.version_rank = 1
LEFT JOIN MeasurementPhase4 mp4
    ON mp0.measurementid = mp4.measurementid
    AND mp4.version_rank = 1
WHERE cp0.version_rank = 2
),

-- Write code to get criteria_results match percentage and measurement_results match percentage

match_calculations AS (
    SELECT 
        LearnerName,
        Apprentice_ULN,
        submission_name,
        -- Calculate total counts
        COUNT(*) as total_criteria,
        SUM(CASE WHEN criteria_results_match = 'True' THEN 1 ELSE 0 END) as matching_criteria,
        COUNT(measurement_code) as total_measurements,
        SUM(CASE WHEN measurement_results_match = 'True' THEN 1 ELSE 0 END) as matching_measurements
    FROM result_query
    GROUP BY 
        LearnerName,
        Apprentice_ULN,
        submission_name
)

SELECT 
    LearnerName,
    Apprentice_ULN,
    submission_name,
    -- Calculate percentages
    CAST(ROUND(
        (CAST(matching_criteria AS FLOAT) / NULLIF(total_criteria, 0)) * 100, 
        2
    ) AS DECIMAL(5,2)) as criteria_match_percentage,
    CAST(ROUND(
        (CAST(matching_measurements AS FLOAT) / NULLIF(total_measurements, 0)) * 100,
        2
    ) AS DECIMAL(5,2)) as measurement_match_percentage,
    -- Include raw counts for verification
    matching_criteria,
    total_criteria,
    matching_measurements,
    total_measurements
FROM match_calculations;

