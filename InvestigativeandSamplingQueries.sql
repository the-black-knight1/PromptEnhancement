--- Sampling learners to analyse
SELECT *
FROM LearnerSubmission LS
JOIN [Standard] S
ON LS.standard_id = S.id
WHERE phase >= 4 AND created_at BETWEEN '2024-11-15' AND '2024-11-30' AND Subs_Path IS NOT NULL AND S.name IN ('Data analyst IFAv1.1', 'Data engineer IFAv1.0')
;


-- ================== Ajinkya's query to investigate ==================
-- SELECT SubmissionAssessmentMeasurementResultsHistory.* from SubmissionAssessmentMeasurementResultsHistory where submission_assessment_criteria_id in (
--     SELECT id from SubmissionAssessmentCriteria where submission_assessment_id in (
--         SELECT id from SubmissionAssessment where learner_submission_id = 'e7065a2e-6413-4db1-9ee4-05c8b8de1741'
--     )
-- )

-- SELECT * from SubmissionAssessmentCriteriaHistory where submission_assessment_id in (
--     SELECT id from SubmissionAssessment where learner_submission_id = 'e7065a2e-6413-4db1-9ee4-05c8b8de1741'
-- )
--- ================== Ajinkya's query to investigate ==================

--- Cannot take just any learner, need to take learners who have submitted at least 4 submissions
--- Focusing on some fixed standards for now; ('Data analyst IFAv1.1', 'Data engineer IFAv1.0')
--- Sampling five learners by Learner ID:
-- 661baa7f-604c-4248-9cb4-9095e8918f27
-- 17fe04d9-689e-4758-a171-f25868a8006d
-- d679d744-d9d9-47a6-acc8-d972dd2f765d
-- 762ef0ee-f5af-441e-8b8e-ee15721f0d6b
-- 9c279464-f202-4f8d-99f7-06d27d859a3d
-- Put them in list format: ('661baa7f-604c-4248-9cb4-9095e8918f27', '17fe04d9-689e-4758-a171-f25868a8006d', 'd679d744-d9d9-47a6-acc8-d972dd2f765d', '762ef0ee-f5af-441e-8b8e-ee15721f0d6b', '9c279464-f202-4f8d-99f7-06d27d859a3d')


-- Getting LearnerSubmission id for these learners

SELECT *
FROM LearnerSubmission
WHERE learner_id IN ('661baa7f-604c-4248-9cb4-9095e8918f27', '17fe04d9-689e-4758-a171-f25868a8006d', 'd679d744-d9d9-47a6-acc8-d972dd2f765d', '762ef0ee-f5af-441e-8b8e-ee15721f0d6b', '9c279464-f202-4f8d-99f7-06d27d859a3d') AND submission_name NOT LIKE '%retry%';


--- ================ Getting the Submission Ids for these learners ====================
--- For Learner ID: 661baa7f-604c-4248-9cb4-9095e8918f27, Submission IDs: (d18ccb47-2c10-456b-8c06-00223433458c, d0ae64f4-beed-4ed6-95e4-ab445c24a3de)

-- Getting All Details on criteria and measurement level for this learner:

--- Getting the Submission Assessment details for this learner (661baa7f-604c-4248-9cb4-9095e8918f27);

WITH OverallCriteriaLevelResults AS 
(
SELECT L.firstname + ' ' + L.surname AS LearnerName,
       L.Apprentice_ULN,
       LS.submission_name, 
       SACH.submission_assessment_id,
       SACH.assessment_grading_criteria_id,
       AGC.code CriteriaCode,
       AGC.[description] CriteriaDescription,
       SACH.result,
       SACH.[version],
       SACH.phase,
       SACH.created_at
FROM SubmissionAssessment SA
JOIN SubmissionAssessmentCriteriaHistory SACH
    ON SA.id = SACH.submission_assessment_id
JOIN AssessmentGradingCriteria AGC
    ON SACH.assessment_grading_criteria_id = AGC.id
JOIN LearnerSubmission LS
    ON SA.learner_submission_id = LS.id
JOIN Learner L
    ON LS.learner_id = L.id 
WHERE LS.learner_id = '661baa7f-604c-4248-9cb4-9095e8918f27' AND LS.submission_name NOT LIKE '%retry%'
),
VersionRanks AS (
    SELECT *,
           FIRST_VALUE(result) OVER (
               PARTITION BY assessment_grading_criteria_id 
               ORDER BY [version]
           ) as first_version_result,
           FIRST_VALUE(created_at) OVER (
               PARTITION BY assessment_grading_criteria_id 
               ORDER BY [version]
           ) as first_version_date,
           LAST_VALUE(result) OVER (
               PARTITION BY assessment_grading_criteria_id 
               ORDER BY [version]
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
           ) as latest_version_result,
           LAST_VALUE(created_at) OVER (
               PARTITION BY assessment_grading_criteria_id 
               ORDER BY [version]
               ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
           ) as latest_version_date,
           MIN([version]) OVER (
               PARTITION BY assessment_grading_criteria_id
           ) as min_version,
           MAX([version]) OVER (
               PARTITION BY assessment_grading_criteria_id
           ) as max_version
    FROM OverallCriteriaLevelResults
)
SELECT DISTINCT
    LearnerName,
    Apprentice_ULN,
    submission_name,
    CriteriaCode,
    CriteriaDescription,
    min_version,
    first_version_result as min_version_result,
    first_version_date as min_version_date,
    max_version,
    latest_version_result as max_version_result,
    latest_version_date as max_version_date
FROM VersionRanks
ORDER BY CriteriaCode;

 

SELECT L.firstname + ' ' + L.surname AS LearnerName,
       L.Apprentice_ULN,
       LS.submission_name, 
       SACH.submission_assessment_id,
       SACH.assessment_grading_criteria_id,
       AGC.code CriteriaCode,
       AGC.[description] CriteriaDescription,
       SACH.result,
       SACH.[version],
       SACH.phase,
       SACH.created_at
FROM SubmissionAssessment SA
JOIN SubmissionAssessmentCriteriaHistory SACH
    ON SA.id = SACH.submission_assessment_id
JOIN AssessmentGradingCriteria AGC
    ON SACH.assessment_grading_criteria_id = AGC.id
JOIN LearnerSubmission LS
    ON SA.learner_submission_id = LS.id
JOIN Learner L
    ON LS.learner_id = L.id 
WHERE LS.learner_id = '9c279464-f202-4f8d-99f7-06d27d859a3d' AND LS.submission_name NOT LIKE '%retry%'

SELECT [Standard].name,
       LearnerSubmission.*
FROM LearnerSubmission
JOIN [Standard] 
    ON [Standard].id = LearnerSubmission.standard_id
WHERE learner_id = '9c279464-f202-4f8d-99f7-06d27d859a3d' AND submission_name NOT LIKE '%retry%' and assessment_stage = 1;