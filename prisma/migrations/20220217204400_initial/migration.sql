-- CreateEnum
CREATE TYPE "Mode" AS ENUM ('TW', 'SZ', 'TC', 'RM', 'CB');

-- CreateEnum
CREATE TYPE "BracketType" AS ENUM ('SE', 'DE');

-- CreateEnum
CREATE TYPE "TeamOrder" AS ENUM ('UPPER', 'LOWER');

-- CreateEnum
CREATE TYPE "LfgGroupType" AS ENUM ('TWIN', 'QUAD', 'VERSUS');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "discordId" TEXT NOT NULL,
    "discordName" TEXT NOT NULL,
    "discordDiscriminator" TEXT NOT NULL,
    "discordAvatar" TEXT,
    "discordRefreshToken" TEXT NOT NULL,
    "twitch" TEXT,
    "twitter" TEXT,
    "youtubeId" TEXT,
    "youtubeName" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Organization" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameForUrl" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "discordInvite" TEXT NOT NULL,
    "twitter" TEXT,

    CONSTRAINT "Organization_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Tournament" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameForUrl" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "checkInStartTime" TIMESTAMP(3) NOT NULL,
    "bannerBackground" TEXT NOT NULL,
    "bannerTextHSLArgs" TEXT NOT NULL,
    "seeds" TEXT[],
    "organizerId" TEXT NOT NULL,

    CONSTRAINT "Tournament_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Stage" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "mode" "Mode" NOT NULL,

    CONSTRAINT "Stage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentTeam" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "tournamentId" TEXT NOT NULL,
    "canHost" BOOLEAN NOT NULL DEFAULT true,
    "friendCode" TEXT NOT NULL,
    "roomPass" TEXT,
    "inviteCode" TEXT NOT NULL,
    "checkedInTime" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TournamentTeam_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentTeamMember" (
    "memberId" TEXT NOT NULL,
    "teamId" TEXT NOT NULL,
    "tournamentId" TEXT NOT NULL,
    "captain" BOOLEAN NOT NULL DEFAULT false
);

-- CreateTable
CREATE TABLE "TrustRelationships" (
    "trustGiverId" TEXT NOT NULL,
    "trustReceiverId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "TournamentBracket" (
    "id" TEXT NOT NULL,
    "tournamentId" TEXT NOT NULL,
    "type" "BracketType" NOT NULL,

    CONSTRAINT "TournamentBracket_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentRound" (
    "id" TEXT NOT NULL,
    "position" INTEGER NOT NULL,
    "bracketId" TEXT NOT NULL,

    CONSTRAINT "TournamentRound_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentRoundStage" (
    "id" TEXT NOT NULL,
    "position" INTEGER NOT NULL,
    "roundId" TEXT NOT NULL,
    "stageId" INTEGER NOT NULL,

    CONSTRAINT "TournamentRoundStage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentMatch" (
    "id" TEXT NOT NULL,
    "roundId" TEXT NOT NULL,
    "position" INTEGER NOT NULL,
    "winnerDestinationMatchId" TEXT,
    "loserDestinationMatchId" TEXT,

    CONSTRAINT "TournamentMatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentMatchParticipant" (
    "order" "TeamOrder" NOT NULL,
    "teamId" TEXT NOT NULL,
    "matchId" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "TournamentMatchGameResult" (
    "id" TEXT NOT NULL,
    "matchId" TEXT NOT NULL,
    "roundStageId" TEXT NOT NULL,
    "winner" "TeamOrder" NOT NULL,
    "reporterId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TournamentMatchGameResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LfgGroup" (
    "id" TEXT NOT NULL,
    "ranked" BOOLEAN,
    "type" "LfgGroupType" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "looking" BOOLEAN NOT NULL,
    "matchId" TEXT,
    "inviteCode" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastActionAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LfgGroup_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LfgGroupLike" (
    "likerId" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "LfgGroupMember" (
    "groupId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "captain" BOOLEAN NOT NULL DEFAULT false
);

-- CreateTable
CREATE TABLE "LfgGroupMatch" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LfgGroupMatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LfgGroupMatchStage" (
    "lfgGroupMatchId" TEXT NOT NULL,
    "stageId" INTEGER NOT NULL,
    "order" INTEGER NOT NULL,
    "winnerGroupId" TEXT
);

-- CreateTable
CREATE TABLE "Skill" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "mu" DOUBLE PRECISION NOT NULL,
    "sigma" DOUBLE PRECISION NOT NULL,
    "matchId" TEXT,
    "tournamentId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Skill_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "_StageToTournament" (
    "A" INTEGER NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "_TournamentMatchGameResultToUser" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "User_discordId_key" ON "User"("discordId");

-- CreateIndex
CREATE UNIQUE INDEX "Organization_nameForUrl_key" ON "Organization"("nameForUrl");

-- CreateIndex
CREATE UNIQUE INDEX "Organization_ownerId_key" ON "Organization"("ownerId");

-- CreateIndex
CREATE UNIQUE INDEX "Tournament_nameForUrl_organizerId_key" ON "Tournament"("nameForUrl", "organizerId");

-- CreateIndex
CREATE UNIQUE INDEX "TournamentTeam_name_tournamentId_key" ON "TournamentTeam"("name", "tournamentId");

-- CreateIndex
CREATE UNIQUE INDEX "TournamentTeamMember_memberId_tournamentId_key" ON "TournamentTeamMember"("memberId", "tournamentId");

-- CreateIndex
CREATE UNIQUE INDEX "TrustRelationships_trustGiverId_trustReceiverId_key" ON "TrustRelationships"("trustGiverId", "trustReceiverId");

-- CreateIndex
CREATE UNIQUE INDEX "TournamentRoundStage_position_roundId_key" ON "TournamentRoundStage"("position", "roundId");

-- CreateIndex
CREATE UNIQUE INDEX "TournamentMatchParticipant_teamId_matchId_key" ON "TournamentMatchParticipant"("teamId", "matchId");

-- CreateIndex
CREATE UNIQUE INDEX "TournamentMatchGameResult_matchId_roundStageId_key" ON "TournamentMatchGameResult"("matchId", "roundStageId");

-- CreateIndex
CREATE INDEX "LfgGroup_active_idx" ON "LfgGroup"("active");

-- CreateIndex
CREATE INDEX "LfgGroup_looking_idx" ON "LfgGroup"("looking");

-- CreateIndex
CREATE INDEX "LfgGroup_type_idx" ON "LfgGroup"("type");

-- CreateIndex
CREATE UNIQUE INDEX "LfgGroupLike_likerId_targetId_key" ON "LfgGroupLike"("likerId", "targetId");

-- CreateIndex
CREATE UNIQUE INDEX "LfgGroupMember_groupId_memberId_key" ON "LfgGroupMember"("groupId", "memberId");

-- CreateIndex
CREATE UNIQUE INDEX "LfgGroupMatchStage_lfgGroupMatchId_order_key" ON "LfgGroupMatchStage"("lfgGroupMatchId", "order");

-- CreateIndex
CREATE UNIQUE INDEX "Skill_userId_matchId_key" ON "Skill"("userId", "matchId");

-- CreateIndex
CREATE UNIQUE INDEX "Skill_userId_tournamentId_key" ON "Skill"("userId", "tournamentId");

-- CreateIndex
CREATE UNIQUE INDEX "_StageToTournament_AB_unique" ON "_StageToTournament"("A", "B");

-- CreateIndex
CREATE INDEX "_StageToTournament_B_index" ON "_StageToTournament"("B");

-- CreateIndex
CREATE UNIQUE INDEX "_TournamentMatchGameResultToUser_AB_unique" ON "_TournamentMatchGameResultToUser"("A", "B");

-- CreateIndex
CREATE INDEX "_TournamentMatchGameResultToUser_B_index" ON "_TournamentMatchGameResultToUser"("B");

-- AddForeignKey
ALTER TABLE "Organization" ADD CONSTRAINT "Organization_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Tournament" ADD CONSTRAINT "Tournament_organizerId_fkey" FOREIGN KEY ("organizerId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentTeam" ADD CONSTRAINT "TournamentTeam_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentTeamMember" ADD CONSTRAINT "TournamentTeamMember_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentTeamMember" ADD CONSTRAINT "TournamentTeamMember_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "TournamentTeam"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrustRelationships" ADD CONSTRAINT "TrustRelationships_trustGiverId_fkey" FOREIGN KEY ("trustGiverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrustRelationships" ADD CONSTRAINT "TrustRelationships_trustReceiverId_fkey" FOREIGN KEY ("trustReceiverId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentBracket" ADD CONSTRAINT "TournamentBracket_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentRound" ADD CONSTRAINT "TournamentRound_bracketId_fkey" FOREIGN KEY ("bracketId") REFERENCES "TournamentBracket"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentRoundStage" ADD CONSTRAINT "TournamentRoundStage_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentRoundStage" ADD CONSTRAINT "TournamentRoundStage_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "TournamentRound"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "TournamentRound"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_winnerDestinationMatchId_fkey" FOREIGN KEY ("winnerDestinationMatchId") REFERENCES "TournamentMatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatch" ADD CONSTRAINT "TournamentMatch_loserDestinationMatchId_fkey" FOREIGN KEY ("loserDestinationMatchId") REFERENCES "TournamentMatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatchParticipant" ADD CONSTRAINT "TournamentMatchParticipant_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "TournamentTeam"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatchParticipant" ADD CONSTRAINT "TournamentMatchParticipant_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "TournamentMatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatchGameResult" ADD CONSTRAINT "TournamentMatchGameResult_roundStageId_fkey" FOREIGN KEY ("roundStageId") REFERENCES "TournamentRoundStage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentMatchGameResult" ADD CONSTRAINT "TournamentMatchGameResult_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "TournamentMatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroup" ADD CONSTRAINT "LfgGroup_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "LfgGroupMatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupLike" ADD CONSTRAINT "LfgGroupLike_likerId_fkey" FOREIGN KEY ("likerId") REFERENCES "LfgGroup"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupLike" ADD CONSTRAINT "LfgGroupLike_targetId_fkey" FOREIGN KEY ("targetId") REFERENCES "LfgGroup"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupMember" ADD CONSTRAINT "LfgGroupMember_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupMember" ADD CONSTRAINT "LfgGroupMember_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "LfgGroup"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupMatchStage" ADD CONSTRAINT "LfgGroupMatchStage_stageId_fkey" FOREIGN KEY ("stageId") REFERENCES "Stage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupMatchStage" ADD CONSTRAINT "LfgGroupMatchStage_winnerGroupId_fkey" FOREIGN KEY ("winnerGroupId") REFERENCES "LfgGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LfgGroupMatchStage" ADD CONSTRAINT "LfgGroupMatchStage_lfgGroupMatchId_fkey" FOREIGN KEY ("lfgGroupMatchId") REFERENCES "LfgGroupMatch"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Skill" ADD CONSTRAINT "Skill_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Skill" ADD CONSTRAINT "Skill_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "Tournament"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Skill" ADD CONSTRAINT "Skill_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "LfgGroupMatch"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_StageToTournament" ADD FOREIGN KEY ("A") REFERENCES "Stage"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_StageToTournament" ADD FOREIGN KEY ("B") REFERENCES "Tournament"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_TournamentMatchGameResultToUser" ADD FOREIGN KEY ("A") REFERENCES "TournamentMatchGameResult"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_TournamentMatchGameResultToUser" ADD FOREIGN KEY ("B") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

--
--
-- The below was added manually
--
--
--

INSERT INTO "Stage" (id, name, mode)
VALUES 
    (1, 'The Reef', 'TW'),
    (2, 'Musselforge Fitness', 'TW'),
    (3, 'Starfish Mainstage', 'TW'),
    (4, 'Humpback Pump Track', 'TW'),
    (5, 'Inkblot Art Academy', 'TW'),
    (6, 'Sturgeon Shipyard', 'TW'),
    (7, 'Moray Towers', 'TW'),
    (8, 'Port Mackerel', 'TW'),
    (9, 'Manta Maria', 'TW'),
    (10, 'Kelp Dome', 'TW'),
    (11, 'Snapper Canal', 'TW'),
    (12, 'Blackbelly Skatepark', 'TW'),
    (13, 'MakoMart', 'TW'),
    (14, 'Walleye Warehouse', 'TW'),
    (15, 'Shellendorf Institute', 'TW'),
    (16, 'Arowana Mall', 'TW'),
    (17, 'Goby Arena', 'TW'),
    (18, 'Piranha Pit', 'TW'),
    (19, 'Camp Triggerfish', 'TW'),
    (20, 'Wahoo World', 'TW'),
    (21, 'New Albacore Hotel', 'TW'),
    (22, 'Ancho-V Games', 'TW'),
    (23, 'Skipper Pavilion', 'TW'),
    (24, 'The Reef', 'SZ'),
    (25, 'Musselforge Fitness', 'SZ'),
    (26, 'Starfish Mainstage', 'SZ'),
    (27, 'Humpback Pump Track', 'SZ'),
    (28, 'Inkblot Art Academy', 'SZ'),
    (29, 'Sturgeon Shipyard', 'SZ'),
    (30, 'Moray Towers', 'SZ'),
    (31, 'Port Mackerel', 'SZ'),
    (32, 'Manta Maria', 'SZ'),
    (33, 'Kelp Dome', 'SZ'),
    (34, 'Snapper Canal', 'SZ'),
    (35, 'Blackbelly Skatepark', 'SZ'),
    (36, 'MakoMart', 'SZ'),
    (37, 'Walleye Warehouse', 'SZ'),
    (38, 'Shellendorf Institute', 'SZ'),
    (39, 'Arowana Mall', 'SZ'),
    (40, 'Goby Arena', 'SZ'),
    (41, 'Piranha Pit', 'SZ'),
    (42, 'Camp Triggerfish', 'SZ'),
    (43, 'Wahoo World', 'SZ'),
    (44, 'New Albacore Hotel', 'SZ'),
    (45, 'Ancho-V Games', 'SZ'),
    (46, 'Skipper Pavilion', 'SZ'),
    (47, 'The Reef', 'TC'),
    (48, 'Musselforge Fitness', 'TC'),
    (49, 'Starfish Mainstage', 'TC'),
    (50, 'Humpback Pump Track', 'TC'),
    (51, 'Inkblot Art Academy', 'TC'),
    (52, 'Sturgeon Shipyard', 'TC'),
    (53, 'Moray Towers', 'TC'),
    (54, 'Port Mackerel', 'TC'),
    (55, 'Manta Maria', 'TC'),
    (56, 'Kelp Dome', 'TC'),
    (57, 'Snapper Canal', 'TC'),
    (58, 'Blackbelly Skatepark', 'TC'),
    (59, 'MakoMart', 'TC'),
    (60, 'Walleye Warehouse', 'TC'),
    (61, 'Shellendorf Institute', 'TC'),
    (62, 'Arowana Mall', 'TC'),
    (63, 'Goby Arena', 'TC'),
    (64, 'Piranha Pit', 'TC'),
    (65, 'Camp Triggerfish', 'TC'),
    (66, 'Wahoo World', 'TC'),
    (67, 'New Albacore Hotel', 'TC'),
    (68, 'Ancho-V Games', 'TC'),
    (69, 'Skipper Pavilion', 'TC'),
    (70, 'The Reef', 'RM'),
    (71, 'Musselforge Fitness', 'RM'),
    (72, 'Starfish Mainstage', 'RM'),
    (73, 'Humpback Pump Track', 'RM'),
    (74, 'Inkblot Art Academy', 'RM'),
    (75, 'Sturgeon Shipyard', 'RM'),
    (76, 'Moray Towers', 'RM'),
    (77, 'Port Mackerel', 'RM'),
    (78, 'Manta Maria', 'RM'),
    (79, 'Kelp Dome', 'RM'),
    (80, 'Snapper Canal', 'RM'),
    (81, 'Blackbelly Skatepark', 'RM'),
    (82, 'MakoMart', 'RM'),
    (83, 'Walleye Warehouse', 'RM'),
    (84, 'Shellendorf Institute', 'RM'),
    (85, 'Arowana Mall', 'RM'),
    (86, 'Goby Arena', 'RM'),
    (87, 'Piranha Pit', 'RM'),
    (88, 'Camp Triggerfish', 'RM'),
    (89, 'Wahoo World', 'RM'),
    (90, 'New Albacore Hotel', 'RM'),
    (91, 'Ancho-V Games', 'RM'),
    (92, 'Skipper Pavilion', 'RM'),
    (93, 'The Reef', 'CB'),
    (94, 'Musselforge Fitness', 'CB'),
    (95, 'Starfish Mainstage', 'CB'),
    (96, 'Humpback Pump Track', 'CB'),
    (97, 'Inkblot Art Academy', 'CB'),
    (98, 'Sturgeon Shipyard', 'CB'),
    (99, 'Moray Towers', 'CB'),
    (100, 'Port Mackerel', 'CB'),
    (101, 'Manta Maria', 'CB'),
    (102, 'Kelp Dome', 'CB'),
    (103, 'Snapper Canal', 'CB'),
    (104, 'Blackbelly Skatepark', 'CB'),
    (105, 'MakoMart', 'CB'),
    (106, 'Walleye Warehouse', 'CB'),
    (107, 'Shellendorf Institute', 'CB'),
    (108, 'Arowana Mall', 'CB'),
    (109, 'Goby Arena', 'CB'),
    (110, 'Piranha Pit', 'CB'),
    (111, 'Camp Triggerfish', 'CB'),
    (112, 'Wahoo World', 'CB'),
    (113, 'New Albacore Hotel', 'CB'),
    (114, 'Ancho-V Games', 'CB'),
    (115, 'Skipper Pavilion', 'CB');
