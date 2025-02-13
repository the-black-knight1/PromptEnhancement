WITH LatestPhase4Results AS (
    SELECT 
        AMC.sub_code,
        SAMRH.evidence_review_result as result,
        SAMRH.version,
        ROW_NUMBER() OVER (
            PARTITION BY AMC.sub_code 
            ORDER BY SAMRH.version DESC
        ) as rn
    FROM SubmissionAssessment SA
    JOIN SubmissionAssessmentCriteriaHistory SACH
        ON SA.id = SACH.submission_assessment_id
    JOIN SubmissionAssessmentMeasurementResultsHistory SAMRH
        ON SACH.id = SAMRH.submission_assessment_criteria_id
    JOIN AssessmentMeasurementCriteria AMC
        ON SAMRH.assessment_measurement_criteria_id = AMC.id
    JOIN LearnerSubmission LS
        ON SA.learner_submission_id = LS.id
    WHERE LS.learner_id = 'd679d744-d9d9-47a6-acc8-d972dd2f765d'
    AND LS.submission_name NOT LIKE '%retry%'
    AND SAMRH.phase = 4
)
SELECT 
    sub_code,
    result,
    version
FROM LatestPhase4Results
WHERE rn = 1