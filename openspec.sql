PGDMP     9                    v            openspec    9.5.14    10.4 �    J	           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            K	           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            L	           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            M	           1262    16385    openspec    DATABASE     z   CREATE DATABASE openspec WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';
    DROP DATABASE openspec;
             admin    false            N	           0    0    DATABASE openspec    COMMENT     F   COMMENT ON DATABASE openspec IS 'database to test Tree and S tables';
                  admin    false    2381                        2615    16386    openspec    SCHEMA        CREATE SCHEMA openspec;
    DROP SCHEMA openspec;
             admin    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
             postgres    false            O	           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                  postgres    false    6            P	           0    0    SCHEMA public    ACL     �   REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
                  postgres    false    6                        3079    12393    plpgsql 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    DROP EXTENSION plpgsql;
                  false            Q	           0    0    EXTENSION plpgsql    COMMENT     @   COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
                       false    1            �            1255    16929    usp_getfirstnodes()    FUNCTION     r  CREATE FUNCTION openspec.usp_getfirstnodes(OUT "ID" bigint, OUT "Name" text, OUT "Order" bigint, OUT "Parent" bigint) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY
	SELECT "S"."ID", "S"."Name", "Tree"."Order", "Tree"."Parent"
	FROM openspec."S"
	LEFT JOIN openspec."Tree"
		ON "S"."ID" = "Tree"."Child"
	WHERE "Tree"."Child" IS NULL;

END;
$$;
 u   DROP FUNCTION openspec.usp_getfirstnodes(OUT "ID" bigint, OUT "Name" text, OUT "Order" bigint, OUT "Parent" bigint);
       openspec       admin    false    8    1            �            1255    17098    usp_gettree()    FUNCTION     q  CREATE FUNCTION openspec.usp_gettree() RETURNS TABLE("ID" integer, "Name" character varying, "Order" integer, parent integer, "ParentsCount" integer, "ChildrenCount" bigint)
    LANGUAGE plpgsql
    AS $$

BEGIN

	CREATE TEMP TABLE IF NOT EXISTS arbol (
		ID INT,
		Name VARCHAR(255),
		"Order" INT,
		Parent INT
	);

	INSERT INTO arbol (ID, Name, "Order", Parent)
	SELECT "S"."id", "S"."name", "Tree"."n_order", "Tree"."parent"
	FROM openspec."S"
	LEFT JOIN openspec."Tree"
		ON "S"."id" = "Tree"."child"
	WHERE "Tree"."child" IS NULL
	UNION ALL
	SELECT "S"."id", "S"."name", "Tree"."n_order", "Tree"."parent"
	FROM openspec."S"
	INNER JOIN openspec."Tree"
		ON "S"."id" = "Tree"."child";

	RETURN QUERY
	WITH RECURSIVE arbolSinHijos ("ID", "Name", "Order", "ParentId", "CountParents") AS   
	(
		SELECT arbol.ID, arbol.Name, arbol."Order", arbol.Parent, 0
		FROM arbol
		WHERE arbol.Parent IS NULL
		UNION ALL
		SELECT arbol.ID, arbol.Name, arbol."Order", arbol.Parent, C."CountParents" + 1
		FROM arbol
		INNER JOIN arbolSinHijos AS C
			ON arbol.Parent = C."ID"
	), childCount(ParentID) AS(
		SELECT arbol.Parent FROM arbol
		UNION ALL
		SELECT i.Parent FROM childCount c
		INNER JOIN arbol i ON c.ParentID = i.ID
	)
	
	--SELECT *
	--FROM arbolSinHijos
	--WHERE "ID" = 173
	
	SELECT T."ID", T."Name", T."Order", T."ParentId", T."CountParents", T."CountChildNode"
	FROM (
		SELECT ash."ID", 
			ash."Name", 
			ash."Order", 
			ash."ParentId", 
			ash."CountParents", 
			CASE WHEN cc."CountChildNode" IS NULL THEN 0 ELSE cc."CountChildNode" END AS "CountChildNode",
			ROW_NUMBER() OVER (PARTITION BY ash."ID" ORDER BY ash."CountParents" DESC) ROWNUM
		FROM arbolSinHijos ash
		LEFT JOIN (
			SELECT ParentID, count(*) "CountChildNode"
			FROM childCount
			GROUP BY ParentID
			ORDER BY ParentID
			) cc
			ON ash."ID" = cc.ParentID
	) T
	WHERE T.ROWNUM = 1;

	DROP TABLE IF EXISTS arbol;

END;

$$;
 &   DROP FUNCTION openspec.usp_gettree();
       openspec       admin    false    8    1            �            1255    17826    usp_gettreefromnode(integer)    FUNCTION     �  CREATE FUNCTION openspec.usp_gettreefromnode(uid integer) RETURNS TABLE("ID" integer, "Name" character varying, "Order" integer, parent integer, "ParentsCount" integer, "ChildrenCount" bigint)
    LANGUAGE plpgsql
    AS $$

BEGIN

	CREATE TEMP TABLE IF NOT EXISTS arbol (
		ID INT,
		Name VARCHAR(255),
		"Order" INT,
		Parent INT
	);

	INSERT INTO arbol (ID, Name, "Order", Parent)
	SELECT "S"."id", "S"."name", "Tree"."n_order", "Tree"."parent"
	FROM openspec."S"
	LEFT JOIN openspec."Tree"
		ON "S"."id" = "Tree"."child"
	WHERE "Tree"."child" IS NULL
	UNION ALL
	SELECT "S"."id", "S"."name", "Tree"."n_order", "Tree"."parent"
	FROM openspec."S"
	INNER JOIN openspec."Tree"
		ON "S"."id" = "Tree"."child";

	RETURN QUERY
	WITH RECURSIVE arbolSinHijos ("ID", "Name", "Order", "ParentId", "CountParents") AS   
	(
		SELECT arbol.ID, arbol.Name, arbol."Order", arbol.Parent, 0
		FROM arbol
		WHERE arbol.Parent IS NULL
		UNION ALL
		SELECT arbol.ID, arbol.Name, arbol."Order", arbol.Parent, C."CountParents" + 1
		FROM arbol
		INNER JOIN arbolSinHijos AS C
			ON arbol.Parent = C."ID"
	), childCount(ParentID) AS(
		SELECT arbol.Parent FROM arbol
		UNION ALL
		SELECT i.Parent FROM childCount c
		INNER JOIN arbol i ON c.ParentID = i.ID
	), childIdList ("id", "parent") AS (
	    SELECT a."id", a.Parent
		FROM arbol a
		WHERE "id" = uid
		UNION ALL
		SELECT c."id", c.Parent
		FROM arbol c
		JOIN childIdList p ON p."id" = c.Parent
	)
	
	--SELECT *
	--FROM arbolSinHijos
	--WHERE "ID" = 173
	
	SELECT T."ID", T."Name", T."Order", T."ParentId", T."CountParents", T."CountChildNode"
	FROM (
		SELECT ash."ID", 
			ash."Name", 
			ash."Order", 
			ash."ParentId", 
			ash."CountParents", 
			CASE WHEN cc."CountChildNode" IS NULL THEN 0 ELSE cc."CountChildNode" END AS "CountChildNode",
			ROW_NUMBER() OVER (PARTITION BY ash."ID" ORDER BY ash."CountParents" DESC) ROWNUM
		FROM arbolSinHijos ash
		LEFT JOIN (
			SELECT ParentID, count(*) "CountChildNode"
			FROM childCount
			GROUP BY ParentID
			ORDER BY ParentID
			) cc
			ON ash."ID" = cc.ParentID
	) T
	WHERE T.ROWNUM = 1
	  AND T."ID" IN (
		  SELECT cl."id"
		  FROM childIdList cl
		  UNION
		  SELECT cl."parent"
		  FROM childIdList cl
		  );

	DROP TABLE IF EXISTS arbol;

END;

$$;
 9   DROP FUNCTION openspec.usp_gettreefromnode(uid integer);
       openspec       admin    false    1    8            �            1255    17139    usp_reboottables()    FUNCTION      CREATE FUNCTION openspec.usp_reboottables() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN

DELETE FROM openspec."Tree";

DELETE FROM openspec."S";

ALTER TABLE OpenSpec."S"
  DROP CONSTRAINT IF EXISTS "S.Status";

ALTER TABLE OpenSpec."S"
  DROP CONSTRAINT IF EXISTS "S.Share";

ALTER TABLE OpenSpec."S"
  DROP CONSTRAINT IF EXISTS "S.Owner";

ALTER TABLE OpenSpec."S"
  DROP CONSTRAINT IF EXISTS "S.LastUpdateUser";

ALTER TABLE OpenSpec."S"
  DROP CONSTRAINT IF EXISTS "S.CreateUser";

ALTER TABLE OpenSpec."S"
  DROP CONSTRAINT IF EXISTS "S,Type";

INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (1, 1, 'Root', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (4, 275, 'Share', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (5, 275, 'Private', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (6, 275, 'Submitted', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (7, 275, 'Public', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (8, 275, 'Status', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (9, 275, 'Disable', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (10, 275, 'Enable', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (11, 275, 'Recycle', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (12, 275, 'Version', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (13, 275, 'Group', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (14, 275, 'Vendor', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (15, 275, 'Consumer', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (16, 275, 'Field Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (17, 275, 'Line Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (18, 275, 'Native', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (19, 275, 'Delta', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (21, 275, 'Line Group(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (22, 275, 'Subject', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (23, 275, 'Element Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (24, 275, 'Data', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (25, 275, 'Inseperable', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (26, 275, 'Seperable', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (27, 275, 'Accessory', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (29, 275, 'Product Combo', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (30, 275, 'Element Count', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (31, 275, '0', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (32, 275, '≤ 1', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (33, 275, '1', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (34, 275, '≥ 0', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (35, 275, '≥ 1', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (36, 275, 'Expand', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (38, 275, 'Expand Chosen', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (39, 275, 'Expand Full', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (40, 275, 'Element(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (41, 275, 'Option', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (43, 275, 'Query Element(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (44, 275, 'Value Element(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (45, 275, 'Text Element(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (46, 275, 'Num Element(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (47, 275, 'Query Symbol', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (48, 275, 'Query Formula', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (49, 275, 'Query Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (50, 275, 'Line Pattern', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (51, 275, 'Simple Search', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (52, 275, 'Advanced Search', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (53, 275, 'Directory Query', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (56, 275, 'Standard Serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (57, 275, 'Ingredient Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (58, 275, 'Active Ingredient', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (59, 275, 'Non-Active Ingredient', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (61, 275, 'Serving Symbol', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (62, 275, 'Number of Serving(s) per Day', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (63, 275, 'Number of Day(s) per Treatment', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (68, 275, 'Text', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (69, 275, 'Measure', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (70, 275, 'Vote', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (71, 275, 'No', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (72, 275, 'Yes', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (73, 275, 'Maybe', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (74, 69, 'Item', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (75, 276, 'ea.', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (76, 276, 'pack', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (77, 276, 'box', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (78, 69, 'Currency', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (79, 276, 'USD', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (80, 276, 'CNY', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (81, 276, 'EUR', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (82, 276, 'GBP', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (83, 69, 'Length', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (84, 276, 'cm', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (85, 276, 'm', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (86, 69, 'Volume', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (87, 276, 'cc', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (88, 276, 'L', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (89, 69, 'Weight', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (90, 276, 'g', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (91, 276, 'kg', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (93, 275, 'User', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (94, 275, 'Username', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (100, 275, 'Text Pattern', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (105, 275, 'Filename', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (106, 275, 'Hyperlink', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (108, 275, 'Date', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (109, 275, 'Time', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (110, 275, 'Date+Time', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (112, 275, 'E-mail(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (113, 275, 'Phone#(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (114, 275, 'Postal Code', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (117, 275, 'Integer', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (118, 275, 'Ingredient Analysis', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (119, 275, 'Amount of Pd (in Pd-U) per Std Serving (StdSv)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (120, 275, 'Amount of Pd (in Pd-SU) per Std Serving (StdSv)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (121, 275, 'Total Amount of Pd (in Pd-U)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (122, 275, 'Total Amount of Pd (in Pd-SU)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (123, 275, 'Number of I in Pd', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (124, 275, 'Amount of N (in N-U) per Std Serving (StdSv)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (125, 275, 'Amount of N (in N-SU) per Std Serving (StdSv)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (126, 275, 'Math Unit', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (127, 275, 'Num', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (128, 275, 'Pd-U', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (129, 275, 'Pd-SU', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (130, 275, 'C-U', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (131, 275, 'C-SU', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (132, 275, 'N-U', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (133, 275, 'N-SU', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (134, 275, 'Language', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (135, 275, 'English', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (136, 275, 'Chinese', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (137, 275, 'Spanish', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (138, 275, 'French', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (139, 275, 'Germany', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (141, 275, 'Name', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (143, 275, 'Std Unit', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (144, 275, 'Unit Factor', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (145, 275, 'Unit Formula', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (148, 275, 'Dimension Width', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (149, 275, 'Dimension Height', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (152, 275, 'Price Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (153, 275, 'MSRP Price', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (154, 275, 'Amazon.com', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (155, 275, 'eBay.com', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (156, 275, 'Amount Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (157, 275, 'Per Component', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (158, 275, 'Per Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (159, 275, 'Per Serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (160, 275, 'Qty Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (161, 275, 'TBD', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (162, 275, 'Proprietary', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (163, 275, 'Trivial', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (164, 275, 'Estimated', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (165, 275, 'Precisely', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (166, 275, 'Amount Filter', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (167, 275, '=', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (168, 275, '≠', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (169, 275, '≤', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (170, 275, '<', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (171, 275, '≥', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (172, 275, '>', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (173, 275, '≤ .. ≥', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (174, 275, '< .. >', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (175, 275, 'Parent of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (176, 275, 'Text Filter', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (177, 275, 'Starts with', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (178, 275, 'Ends with', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (179, 275, 'has Pattern', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (180, 275, 'Spec Filter', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (181, 275, 'Ancestor of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (182, 275, 'Descendent of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (183, 275, 'Child of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (184, 275, 'Upper Sibling of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (185, 275, 'Lower Sibling of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (186, 275, 'Physical Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (187, 275, 'Item Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (188, 275, 'Main Item', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (189, 275, 'Other Item', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (190, 275, 'Current Session', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (191, 275, 'Current Language', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (192, 275, 'Current User', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (193, 275, 'Current Version', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (194, 275, 'Current Mode', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (195, 275, 'Current Spec', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (197, 275, 'ID', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (198, 275, 'Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (199, 275, 'Directory', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (200, 275, 'Query', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (203, 275, 'Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (204, 275, 'Line', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (205, 275, 'Field', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (209, 275, 'Owner', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (210, 275, 'Parent', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (211, 275, 'Directory(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (212, 275, 'Product Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (213, 275, 'Product Series', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (214, 275, 'Service Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (216, 275, 'Core Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (217, 275, 'Retail Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (218, 275, 'Bulk (OEM) Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (219, 275, 'Product UPC', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (220, 275, 'Amazon ASIN', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (221, 275, 'Product Price(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (222, 275, 'Product Net Amount', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (225, 275, 'Serving Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (226, 275, 'Std Small Serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (227, 275, 'Std Medium Serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (228, 275, 'Std Large Serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (229, 275, 'Adult light serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (230, 275, 'Adult medium serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (231, 275, 'Adult heavy serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (232, 275, 'Senior light serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (233, 275, 'Senior medium serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (234, 275, 'Senior heavy serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (235, 275, 'Child light serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (236, 275, 'Child medium serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (237, 275, 'Child heavy serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (238, 275, 'Infant light serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (239, 275, 'Infant medium serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (240, 275, 'Infant heavy serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (241, 275, 'Unique Name', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (242, 275, 'Group(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (245, 13, 'Session Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (247, 13, 'Product Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (249, 13, 'Query Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (250, 13, 'Directory Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (251, 13, 'User Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (252, 13, 'Ingredient Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (253, 13, 'Measure Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (254, 13, 'Serving Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (255, 13, 'Blank', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (257, 275, 'Prefer Language', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (258, 275, 'Nick Name', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (259, 275, 'DOB', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (260, 275, 'Gender', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (261, 275, 'Male', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (262, 275, 'Female', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (263, 275, 'Other', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (268, 275, 'Time Zone', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (269, 275, 'Country', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (271, 13, 'Contact Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (274, 275, 'Spec', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (275, 275, 'Component', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (276, 275, 'Unit', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (278, 275, 'Icon', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (279, 275, 'Notes', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (280, 275, 'Filter', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (282, 275, 'Match Filter', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (283, 275, 'Match None or One', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (284, 275, 'Match One', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (285, 275, 'Match One or More', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (286, 275, 'Match All', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (287, 275, 'From~', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (288, 275, '~To', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (290, 275, 'Edit', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (291, 275, 'View', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (293, 275, 'Num Pattern', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (299, 275, 'Blend', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (300, 275, 'Leaf Child of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (301, 275, 'Leaf Descendent of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (304, 275, 'is Like', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (307, 275, 'Spec Pattern', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (308, 275, 'Sibling', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (309, 275, 'Amount', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (310, 13, 'Price Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (311, 13, 'Package Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (312, 13, 'Component Info', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (313, 275, 'Regular Price', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (314, 275, 'Member Only Price', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (315, 275, 'Promotional Price', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (316, 275, 'Sales Channel', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (317, 275, 'Online Store', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (318, 275, 'Walmart.com', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (319, 275, 'Target.com', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (320, 275, 'Costco.com', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (321, 275, 'Offline Store', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (322, 275, 'Walmart Stores', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (323, 275, 'Target Stores', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (324, 275, 'Costco Stores', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (328, 275, 'Packaging', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (332, 275, 'Contact', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (333, 275, 'Address', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (334, 275, 'Company', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (335, 275, 'Street', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (336, 275, 'City', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (337, 275, 'State/Province', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (340, 275, 'Online Map(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (341, 275, 'Office Hours', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (342, 275, 'Office', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (343, 275, 'Office Webpage(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (344, 275, 'Office Contact(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (345, 275, 'Office Address', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (347, 275, 'Social IM(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (348, 275, 'Branch Office(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (349, 275, 'Company Webpage(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (352, 275, 'Delta Field', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (353, 275, 'Update Type', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (354, 275, 'Create', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (355, 275, 'Delete', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (359, 275, 'Session', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (362, 275, 'S', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (367, 275, '> 1', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (368, 275, 'Range', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (369, 275, 'History', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (370, 275, 'R/W', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (371, 275, 'RO', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (372, 275, 'RW', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (373, 275, 'Grand Child of', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (375, 275, 'Component | Product', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (385, 275, 'Create Time', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (386, 275, 'Create User', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (387, 275, 'Last Update Time', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (388, 275, 'Last Update User', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (393, 275, 'Packages', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (394, 275, 'Prices', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (395, 275, 'Package Net Amount', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (398, 69, 'Count', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (399, 276, 'dozen', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (400, 276, 'half-dozen', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (402, 275, 'Group | Component', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (403, 275, 'Double', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (405, 275, 'Product Serving(s)', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (406, 275, 'Serving', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (408, 275, 'Line Count', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (409, 275, 'Measures', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (410, 275, 'Countries', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (412, 275, 'Group | Directory', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (413, 275, 'Match None', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (414, 275, 'is a', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (415, 93, 'Admin', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (416, 275, 'Dimension', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (417, 275, 'Dimension Length', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (418, 275, 'Dimension Weight', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');
INSERT INTO OpenSpec."S" ("id", "type", "name", "share", "Owner", "status", "Version", "Icon", "Notes", "create_user", "create_date", "last_update_user", "last_update_date") VALUES (419, 275, 'Dimension Volumne', 7, NULL, 10, NULL, NULL, NULL, 415, '2016-02-14 22:06:00', 415, '2016-02-14 22:06:00');

INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (4, 40000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (5, 10000, 4, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (6, 20000, 4, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (7, 30000, 4, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (8, 50000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (9, 10000, 8, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (10, 20000, 8, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (11, 30000, 8, 353, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (11, 30000, 353, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (12, 60000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (13, 10000, 402, 412, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (13, 10000, 412, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (14, 20000, 12, 193, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (14, 10000, 193, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (15, 30000, 12, 193, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (15, 20000, 193, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (16, 230000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (17, 10000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (18, 10000, 17, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (19, 20000, 17, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (21, 20000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (22, 30000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (23, 40000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (24, 10000, 23, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (25, 20000, 23, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (26, 30000, 23, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (27, 40000, 23, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (29, 60000, 23, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (30, 50000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (31, 10000, 30, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (32, 30000, 30, 408, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (32, 20000, 408, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (33, 40000, 30, 408, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (33, 30000, 408, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (34, 20000, 30, 408, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (34, 10000, 408, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (35, 50000, 30, 408, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (35, 40000, 408, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (36, 60000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (38, 20000, 36, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (39, 10000, 36, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (40, 80000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (41, 90000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (43, 20000, 249, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (44, 10000, 43, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (45, 20000, 43, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (46, 30000, 43, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (47, 150000, 100, 249, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (47, 40000, 249, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (48, 140000, 100, 249, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (48, 30000, 249, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (49, 10000, 249, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (50, 10000, 49, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (51, 20000, 49, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (52, 30000, 49, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (53, 10000, 250, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (56, 15000, 254, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (57, 10000, 252, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (58, 10000, 57, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (59, 20000, 57, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (61, 160000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (61, 20000, 254, 100, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (62, 30000, 254, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (63, 40000, 254, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (68, 10000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (69, 90000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (70, 20000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (71, 10000, 70, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (72, 20000, 70, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (73, 30000, 70, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (74, 40000, 69, 126, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (74, 80000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (75, 10000, 398, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (76, 20000, 74, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (77, 30000, 74, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (78, 20000, 69, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (79, 10000, 78, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (80, 20000, 78, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (81, 30000, 78, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (82, 40000, 78, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (83, 50000, 69, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (84, 10000, 83, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (85, 20000, 83, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (86, 70000, 69, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (87, 10000, 86, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (88, 20000, 86, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (89, 60000, 69, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (90, 10000, 89, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (91, 20000, 89, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (93, 170000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (94, 100000, 100, 251, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (94, 10000, 251, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (100, 50000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (105, 30000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (106, 40000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (108, 70000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (109, 80000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (110, 90000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (112, 110000, 100, 271, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (112, 30000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (113, 120000, 100, 271, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (113, 40000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (114, 130000, 100, 271, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (114, 63000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (117, 20000, 293, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (118, 20000, 252, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (119, 10000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (120, 20000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (121, 30000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (122, 40000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (123, 50000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (124, 60000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (125, 70000, 118, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (126, 190000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (127, 10000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (128, 20000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (129, 30000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (130, 40000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (131, 50000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (132, 60000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (133, 70000, 126, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (134, 140000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (135, 10000, 134, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (136, 20000, 134, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (137, 30000, 134, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (138, 40000, 134, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (139, 50000, 134, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (141, 20000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (143, 20000, 253, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (144, 30000, 253, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (145, 40000, 253, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (148, 20000, 416, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (149, 30000, 416, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (152, 20000, 310, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (153, 10000, 152, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (154, 10000, 317, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (155, 20000, 317, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (156, 170000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (157, 10000, 156, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (158, 20000, 156, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (159, 30000, 156, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (160, 180000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (161, 10000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (162, 30000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (163, 40000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (164, 50000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (165, 60000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (166, 10000, 176, 280, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (166, 10000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (167, 10000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (168, 20000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (169, 30000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (170, 40000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (171, 50000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (172, 60000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (173, 70000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (174, 80000, 166, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (175, 20000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (176, 5000, 180, 280, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (176, 40000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (177, 30000, 176, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (178, 40000, 176, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (179, 60000, 176, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (180, 60000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (181, 25000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (182, 50000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (183, 30000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (184, 70000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (185, 80000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (186, 30000, 212, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (187, 200000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (188, 10000, 187, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (189, 20000, 187, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (190, 10000, 245, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (191, 20000, 245, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (192, 30000, 245, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (193, 40000, 245, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (194, 50000, 245, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (195, 60000, 245, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (197, 10000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (198, 40000, 307, 407, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (199, 20000, 412, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (200, 130000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (203, 20000, 375, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (204, 20000, 198, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (205, 10000, 198, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (209, 70000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (210, 1000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (211, 150000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (212, 10000, 247, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (213, 10000, 212, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (214, 20000, 212, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (216, 10000, 186, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (217, 20000, 186, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (218, 30000, 186, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (219, 50000, 100, 247, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (219, 20000, 247, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (220, 60000, 100, 247, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (220, 30000, 247, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (221, 10000, 310, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (222, 40000, 247, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (225, 50000, 254, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (226, 10000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (227, 20000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (228, 30000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (229, 40000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (230, 50000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (231, 60000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (232, 70000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (233, 80000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (234, 90000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (235, 100000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (236, 110000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (237, 120000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (238, 130000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (239, 140000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (240, 150000, 225, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (241, 20000, 100, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (242, 30000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (245, 130000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (247, 100000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (249, 110000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (250, 40000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (251, 140000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (252, 60000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (253, 70000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (254, 120000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (255, 15000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (257, 10000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (258, 50000, 251, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (259, 30000, 251, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (260, 40000, 251, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (261, 10000, 260, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (262, 20000, 260, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (263, 30000, 260, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (268, 80000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (269, 64000, 271, 274, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (269, 50000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (271, 30000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (274, 30000, 198, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (275, 10000, 375, 402, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (275, 20000, 402, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (276, 180000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (278, 80000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (279, 90000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (280, 220000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (282, 20000, 176, 280, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (282, 20000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (283, 20000, 282, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (284, 30000, 282, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (285, 40000, 282, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (286, 50000, 282, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (287, 70000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (288, 80000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (290, 20000, 194, 353, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (290, 20000, 353, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (291, 10000, 194, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (293, 30000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (299, 10000, 307, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (300, 40000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (301, 60000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (304, 50000, 176, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (307, 70000, 280, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (308, 135000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (309, 100000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (310, 90000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (311, 80000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (312, 20000, 1, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (313, 20000, 152, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (314, 30000, 152, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (315, 40000, 152, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (316, 30000, 310, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (317, 10000, 316, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (318, 30000, 317, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (319, 40000, 317, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (320, 50000, 317, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (321, 20000, 316, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (322, 10000, 321, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (323, 20000, 321, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (324, 30000, 321, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (328, 50000, 23, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (332, 40000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (333, 50000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (333, 10000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (334, 20000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (335, 61000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (336, 60000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (337, 62000, 271, 274, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (337, 160000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (340, 70000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (341, 130000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (342, 100000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (343, 120000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (344, 140000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (345, 150000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (347, 20000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (348, 110000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (349, 100000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (352, 30000, 17, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (353, 160000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (354, 10000, 353, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (355, 40000, 353, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (359, 150000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (362, 30000, 307, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (367, 60000, 30, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (368, 90000, 160, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (369, 20000, 307, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (370, 210000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (371, 20000, 370, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (372, 10000, 370, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (373, 45000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (375, 30000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (385, 110000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (386, 100000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (387, 130000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (388, 120000, 255, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (393, 10000, 311, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (394, 110000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (395, 20000, 311, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (398, 30000, 69, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (399, 30000, 398, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (400, 20000, 398, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (402, 60000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (403, 10000, 293, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (405, 60000, 254, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (406, 10000, 254, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (408, 25000, 16, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (409, 10000, 253, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (410, 65000, 271, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (412, 70000, 274, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (413, 10000, 282, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (414, 10000, 180, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (416, 30000, 311, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (417, 10000, 416, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (418, 50000, 416, NULL, NULL, NULL, NULL);
INSERT INTO OpenSpec."Tree" ("child", "n_order", "parent", "P2", "P3", "P4", "P5") VALUES (419, 40000, 416, NULL, NULL, NULL, NULL);

ALTER TABLE OpenSpec."S"
  ADD CONSTRAINT "S.Status"
  FOREIGN KEY ("status")
    REFERENCES OpenSpec."S"("id");

ALTER TABLE OpenSpec."S"
  ADD CONSTRAINT "S.Share"
  FOREIGN KEY ("share")
    REFERENCES OpenSpec."S"("id");

ALTER TABLE OpenSpec."S"
  ADD CONSTRAINT "S.Owner"
  FOREIGN KEY ("Owner")
    REFERENCES OpenSpec."S"("id");

ALTER TABLE OpenSpec."S"
  ADD CONSTRAINT "S.LastUpdateUser"
  FOREIGN KEY ("last_update_user")
    REFERENCES OpenSpec."S"("id");

ALTER TABLE OpenSpec."S"
  ADD CONSTRAINT "S.CreateUser"
  FOREIGN KEY ("create_user")
    REFERENCES OpenSpec."S"("id");

ALTER TABLE OpenSpec."S"
  ADD CONSTRAINT "S,Type"
  FOREIGN KEY ("type")
    REFERENCES OpenSpec."S"("id");

END;$$;
 +   DROP FUNCTION openspec.usp_reboottables();
       openspec       admin    false    1    8            �            1259    16389    Blend    TABLE     }  CREATE TABLE openspec."Blend" (
    "ID" bigint NOT NULL,
    "Pd" bigint NOT NULL,
    "Pd-U" bigint NOT NULL,
    "Pd-SU" bigint NOT NULL,
    "Pd-UF" double precision NOT NULL,
    "I" bigint NOT NULL,
    "C-U" bigint NOT NULL,
    "C-SU" bigint NOT NULL,
    "C-UF" double precision NOT NULL,
    "StdSv" bigint NOT NULL,
    "Sv" bigint NOT NULL,
    "Ln" bigint NOT NULL
);
    DROP TABLE openspec."Blend";
       openspec         admin    false    8            �            1259    16387    Blend_ID_seq    SEQUENCE     y   CREATE SEQUENCE openspec."Blend_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE openspec."Blend_ID_seq";
       openspec       admin    false    201    8            R	           0    0    Blend_ID_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE openspec."Blend_ID_seq" OWNED BY openspec."Blend"."ID";
            openspec       admin    false    200            �            1259    16395    Field    TABLE     �  CREATE TABLE openspec."Field" (
    "Line" bigint NOT NULL,
    "ID" bigint NOT NULL,
    "FieldType" bigint NOT NULL,
    "Order" bigint NOT NULL,
    "RW" bigint NOT NULL,
    "Expand" bigint NOT NULL,
    "Filter" bigint,
    "Format" bigint,
    "Spec" bigint,
    "Num" double precision,
    "Text" text,
    "AmountType" bigint NOT NULL,
    "QtyType" bigint NOT NULL,
    "Qty" double precision,
    "Qty2" double precision,
    "Measure" bigint NOT NULL,
    "Unit" bigint
);
    DROP TABLE openspec."Field";
       openspec         admin    false    8            �            1259    16405    History    TABLE       CREATE TABLE openspec."History" (
    "ID" bigint NOT NULL,
    "UpdateType" bigint NOT NULL,
    "UpdateDate" timestamp without time zone NOT NULL,
    "UpdateUser" bigint NOT NULL,
    "Spec" bigint NOT NULL,
    "BeforeUpdate" text,
    "AfterUpdate" text
);
    DROP TABLE openspec."History";
       openspec         admin    false    8            �            1259    16403    History_ID_seq    SEQUENCE     {   CREATE SEQUENCE openspec."History_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE openspec."History_ID_seq";
       openspec       admin    false    8    204            S	           0    0    History_ID_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE openspec."History_ID_seq" OWNED BY openspec."History"."ID";
            openspec       admin    false    203            �            1259    16414 
   Ingredient    TABLE     �   CREATE TABLE openspec."Ingredient" (
    "Ln" bigint NOT NULL,
    "N" bigint NOT NULL,
    "N-U" bigint NOT NULL,
    "N-SU" bigint NOT NULL,
    "N-UF" double precision NOT NULL
);
 "   DROP TABLE openspec."Ingredient";
       openspec         admin    false    8            �            1259    16419    Line    TABLE       CREATE TABLE openspec."Line" (
    "ID" bigint NOT NULL,
    "Lt" bigint NOT NULL,
    "Lo" bigint NOT NULL,
    "Spec" bigint NOT NULL,
    "Ef" bigint,
    "E" bigint,
    "EdL" bigint,
    "EdLo" bigint,
    "EdLf" bigint,
    "EL" bigint,
    "ELo" bigint,
    "ELf" bigint
);
    DROP TABLE openspec."Line";
       openspec         admin    false    8            �            1259    16424    Math    TABLE     �   CREATE TABLE openspec."Math" (
    "ID" bigint NOT NULL,
    "MathSymbol" text NOT NULL,
    "MathName" bigint NOT NULL,
    "MathUnit" bigint,
    "MathFormula" text NOT NULL
);
    DROP TABLE openspec."Math";
       openspec         admin    false    8            �            1259    16432 	   QueryProd    TABLE     b   CREATE TABLE openspec."QueryProd" (
    "Query" bigint NOT NULL,
    "Product" bigint NOT NULL
);
 !   DROP TABLE openspec."QueryProd";
       openspec         admin    false    8            �            1259    16439    S    TABLE     �  CREATE TABLE openspec."S" (
    id bigint NOT NULL,
    type bigint NOT NULL,
    name text,
    share bigint NOT NULL,
    "Owner" bigint,
    status bigint NOT NULL,
    "Version" bigint,
    "Icon" text,
    "Notes" text,
    create_user bigint NOT NULL,
    create_date timestamp without time zone DEFAULT now() NOT NULL,
    last_update_user bigint NOT NULL,
    last_update_date timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE openspec."S";
       openspec         admin    false    8            �            1259    16437    S_ID_seq    SEQUENCE     u   CREATE SEQUENCE openspec."S_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE openspec."S_ID_seq";
       openspec       admin    false    8    210            T	           0    0    S_ID_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE openspec."S_ID_seq" OWNED BY openspec."S".id;
            openspec       admin    false    209            �            1259    16450    Session    TABLE     �   CREATE TABLE openspec."Session" (
    "CurrentSession" text NOT NULL,
    "CurrentUser" bigint NOT NULL,
    "CurrentLanguage" bigint NOT NULL,
    "CurrentMode" bigint NOT NULL,
    "CurrentVersion" bigint,
    "CurrentSpec" bigint
);
    DROP TABLE openspec."Session";
       openspec         admin    false    8            �            1259    16458    Tree    TABLE     �   CREATE TABLE openspec."Tree" (
    child bigint NOT NULL,
    n_order bigint NOT NULL,
    parent bigint NOT NULL,
    "P2" bigint,
    "P3" bigint,
    "P4" bigint,
    "P5" bigint
);
    DROP TABLE openspec."Tree";
       openspec         admin    false    8            �            1259    16463    Unit    TABLE     �   CREATE TABLE openspec."Unit" (
    "ID" bigint NOT NULL,
    "Measure" bigint NOT NULL,
    "StdUnit" bigint NOT NULL,
    "UnitFactor" double precision NOT NULL,
    "UnitFormula" text NOT NULL
);
    DROP TABLE openspec."Unit";
       openspec         admin    false    8            �            1259    16471    Yield    TABLE     �   CREATE TABLE openspec."Yield" (
    "Blend" bigint NOT NULL,
    "Math" bigint NOT NULL,
    "Qty" double precision NOT NULL,
    "Unit" bigint
);
    DROP TABLE openspec."Yield";
       openspec         admin    false    8            �            1259    17518    s_seq    SEQUENCE     s   CREATE SEQUENCE openspec.s_seq
    START WITH 420
    INCREMENT BY 1
    MINVALUE 420
    NO MAXVALUE
    CACHE 1;
    DROP SEQUENCE openspec.s_seq;
       openspec       admin    false    210    8            U	           0    0    s_seq    SEQUENCE OWNED BY     8   ALTER SEQUENCE openspec.s_seq OWNED BY openspec."S".id;
            openspec       admin    false    216            �            1259    17515    s_seq    SEQUENCE     q   CREATE SEQUENCE public.s_seq
    START WITH 420
    INCREMENT BY 1
    MINVALUE 420
    NO MAXVALUE
    CACHE 1;
    DROP SEQUENCE public.s_seq;
       public       admin    false    6            5           2604    16392    Blend ID    DEFAULT     n   ALTER TABLE ONLY openspec."Blend" ALTER COLUMN "ID" SET DEFAULT nextval('openspec."Blend_ID_seq"'::regclass);
 =   ALTER TABLE openspec."Blend" ALTER COLUMN "ID" DROP DEFAULT;
       openspec       admin    false    201    200    201            6           2604    16408 
   History ID    DEFAULT     r   ALTER TABLE ONLY openspec."History" ALTER COLUMN "ID" SET DEFAULT nextval('openspec."History_ID_seq"'::regclass);
 ?   ALTER TABLE openspec."History" ALTER COLUMN "ID" DROP DEFAULT;
       openspec       admin    false    203    204    204            9           2604    17520    S id    DEFAULT     _   ALTER TABLE ONLY openspec."S" ALTER COLUMN id SET DEFAULT nextval('openspec.s_seq'::regclass);
 7   ALTER TABLE openspec."S" ALTER COLUMN id DROP DEFAULT;
       openspec       admin    false    216    210            8	          0    16389    Blend 
   TABLE DATA               z   COPY openspec."Blend" ("ID", "Pd", "Pd-U", "Pd-SU", "Pd-UF", "I", "C-U", "C-SU", "C-UF", "StdSv", "Sv", "Ln") FROM stdin;
    openspec       admin    false    201   ��      9	          0    16395    Field 
   TABLE DATA               �   COPY openspec."Field" ("Line", "ID", "FieldType", "Order", "RW", "Expand", "Filter", "Format", "Spec", "Num", "Text", "AmountType", "QtyType", "Qty", "Qty2", "Measure", "Unit") FROM stdin;
    openspec       admin    false    202   ��      ;	          0    16405    History 
   TABLE DATA               |   COPY openspec."History" ("ID", "UpdateType", "UpdateDate", "UpdateUser", "Spec", "BeforeUpdate", "AfterUpdate") FROM stdin;
    openspec       admin    false    204   ��      <	          0    16414 
   Ingredient 
   TABLE DATA               J   COPY openspec."Ingredient" ("Ln", "N", "N-U", "N-SU", "N-UF") FROM stdin;
    openspec       admin    false    205   ��      =	          0    16419    Line 
   TABLE DATA               r   COPY openspec."Line" ("ID", "Lt", "Lo", "Spec", "Ef", "E", "EdL", "EdLo", "EdLf", "EL", "ELo", "ELf") FROM stdin;
    openspec       admin    false    206   �      >	          0    16424    Math 
   TABLE DATA               ]   COPY openspec."Math" ("ID", "MathSymbol", "MathName", "MathUnit", "MathFormula") FROM stdin;
    openspec       admin    false    207   -�      ?	          0    16432 	   QueryProd 
   TABLE DATA               ;   COPY openspec."QueryProd" ("Query", "Product") FROM stdin;
    openspec       admin    false    208   J�      A	          0    16439    S 
   TABLE DATA               �   COPY openspec."S" (id, type, name, share, "Owner", status, "Version", "Icon", "Notes", create_user, create_date, last_update_user, last_update_date) FROM stdin;
    openspec       admin    false    210   g�      B	          0    16450    Session 
   TABLE DATA               �   COPY openspec."Session" ("CurrentSession", "CurrentUser", "CurrentLanguage", "CurrentMode", "CurrentVersion", "CurrentSpec") FROM stdin;
    openspec       admin    false    211   �      C	          0    16458    Tree 
   TABLE DATA               R   COPY openspec."Tree" (child, n_order, parent, "P2", "P3", "P4", "P5") FROM stdin;
    openspec       admin    false    212         D	          0    16463    Unit 
   TABLE DATA               [   COPY openspec."Unit" ("ID", "Measure", "StdUnit", "UnitFactor", "UnitFormula") FROM stdin;
    openspec       admin    false    213   o      E	          0    16471    Yield 
   TABLE DATA               C   COPY openspec."Yield" ("Blend", "Math", "Qty", "Unit") FROM stdin;
    openspec       admin    false    214   �      V	           0    0    Blend_ID_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('openspec."Blend_ID_seq"', 1, false);
            openspec       admin    false    200            W	           0    0    History_ID_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('openspec."History_ID_seq"', 1, false);
            openspec       admin    false    203            X	           0    0    S_ID_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('openspec."S_ID_seq"', 1, false);
            openspec       admin    false    209            Y	           0    0    s_seq    SEQUENCE SET     7   SELECT pg_catalog.setval('openspec.s_seq', 421, true);
            openspec       admin    false    216            Z	           0    0    s_seq    SEQUENCE SET     5   SELECT pg_catalog.setval('public.s_seq', 438, true);
            public       admin    false    215            D           2606    16394    Blend Blend_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend_pkey" PRIMARY KEY ("ID");
 @   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend_pkey";
       openspec         admin    false    201            Q           2606    16402    Field Field_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field_pkey" PRIMARY KEY ("ID");
 @   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field_pkey";
       openspec         admin    false    202            V           2606    16413    History History_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY openspec."History"
    ADD CONSTRAINT "History_pkey" PRIMARY KEY ("ID");
 D   ALTER TABLE ONLY openspec."History" DROP CONSTRAINT "History_pkey";
       openspec         admin    false    204            [           2606    16418    Ingredient Ingredient_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY openspec."Ingredient"
    ADD CONSTRAINT "Ingredient_pkey" PRIMARY KEY ("Ln");
 J   ALTER TABLE ONLY openspec."Ingredient" DROP CONSTRAINT "Ingredient_pkey";
       openspec         admin    false    205            d           2606    16423    Line Line_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line_pkey" PRIMARY KEY ("ID");
 >   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line_pkey";
       openspec         admin    false    206            h           2606    16431    Math Math_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY openspec."Math"
    ADD CONSTRAINT "Math_pkey" PRIMARY KEY ("ID");
 >   ALTER TABLE ONLY openspec."Math" DROP CONSTRAINT "Math_pkey";
       openspec         admin    false    207            k           2606    16436    QueryProd QueryProd_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY openspec."QueryProd"
    ADD CONSTRAINT "QueryProd_pkey" PRIMARY KEY ("Query", "Product");
 H   ALTER TABLE ONLY openspec."QueryProd" DROP CONSTRAINT "QueryProd_pkey";
       openspec         admin    false    208    208            u           2606    16449    S S_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S_pkey" PRIMARY KEY (id);
 8   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S_pkey";
       openspec         admin    false    210            |           2606    16457    Session Session_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY openspec."Session"
    ADD CONSTRAINT "Session_pkey" PRIMARY KEY ("CurrentSession");
 D   ALTER TABLE ONLY openspec."Session" DROP CONSTRAINT "Session_pkey";
       openspec         admin    false    211            �           2606    16462    Tree Tree_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY openspec."Tree"
    ADD CONSTRAINT "Tree_pkey" PRIMARY KEY (child, parent);
 >   ALTER TABLE ONLY openspec."Tree" DROP CONSTRAINT "Tree_pkey";
       openspec         admin    false    212    212            �           2606    16470    Unit Unit_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY openspec."Unit"
    ADD CONSTRAINT "Unit_pkey" PRIMARY KEY ("ID");
 >   ALTER TABLE ONLY openspec."Unit" DROP CONSTRAINT "Unit_pkey";
       openspec         admin    false    213            �           2606    16475    Yield Yield_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY openspec."Yield"
    ADD CONSTRAINT "Yield_pkey" PRIMARY KEY ("Blend");
 @   ALTER TABLE ONLY openspec."Yield" DROP CONSTRAINT "Yield_pkey";
       openspec         admin    false    214            :           1259    16484 
   Blend.C-SU    INDEX     D   CREATE INDEX "Blend.C-SU" ON openspec."Blend" USING btree ("C-SU");
 "   DROP INDEX openspec."Blend.C-SU";
       openspec         admin    false    201            ;           1259    16483 	   Blend.C-U    INDEX     B   CREATE INDEX "Blend.C-U" ON openspec."Blend" USING btree ("C-U");
 !   DROP INDEX openspec."Blend.C-U";
       openspec         admin    false    201            <           1259    16482    Blend.I    INDEX     >   CREATE INDEX "Blend.I" ON openspec."Blend" USING btree ("I");
    DROP INDEX openspec."Blend.I";
       openspec         admin    false    201            =           1259    16481    Blend.Ln    INDEX     @   CREATE INDEX "Blend.Ln" ON openspec."Blend" USING btree ("Ln");
     DROP INDEX openspec."Blend.Ln";
       openspec         admin    false    201            >           1259    16480    Blend.Pd    INDEX     @   CREATE INDEX "Blend.Pd" ON openspec."Blend" USING btree ("Pd");
     DROP INDEX openspec."Blend.Pd";
       openspec         admin    false    201            ?           1259    16479    Blend.Pd-SU    INDEX     F   CREATE INDEX "Blend.Pd-SU" ON openspec."Blend" USING btree ("Pd-SU");
 #   DROP INDEX openspec."Blend.Pd-SU";
       openspec         admin    false    201            @           1259    16478 
   Blend.Pd-U    INDEX     D   CREATE INDEX "Blend.Pd-U" ON openspec."Blend" USING btree ("Pd-U");
 "   DROP INDEX openspec."Blend.Pd-U";
       openspec         admin    false    201            A           1259    16477    Blend.StdSv    INDEX     F   CREATE INDEX "Blend.StdSv" ON openspec."Blend" USING btree ("StdSv");
 #   DROP INDEX openspec."Blend.StdSv";
       openspec         admin    false    201            B           1259    16476    Blend.Sv    INDEX     @   CREATE INDEX "Blend.Sv" ON openspec."Blend" USING btree ("Sv");
     DROP INDEX openspec."Blend.Sv";
       openspec         admin    false    201            E           1259    16495    Field.AmountType    INDEX     P   CREATE INDEX "Field.AmountType" ON openspec."Field" USING btree ("AmountType");
 (   DROP INDEX openspec."Field.AmountType";
       openspec         admin    false    202            F           1259    16494    Field.Expand    INDEX     H   CREATE INDEX "Field.Expand" ON openspec."Field" USING btree ("Expand");
 $   DROP INDEX openspec."Field.Expand";
       openspec         admin    false    202            G           1259    16493    Field.FieldType    INDEX     N   CREATE INDEX "Field.FieldType" ON openspec."Field" USING btree ("FieldType");
 '   DROP INDEX openspec."Field.FieldType";
       openspec         admin    false    202            H           1259    16492    Field.Filter    INDEX     H   CREATE INDEX "Field.Filter" ON openspec."Field" USING btree ("Filter");
 $   DROP INDEX openspec."Field.Filter";
       openspec         admin    false    202            I           1259    16491    Field.Format    INDEX     H   CREATE INDEX "Field.Format" ON openspec."Field" USING btree ("Format");
 $   DROP INDEX openspec."Field.Format";
       openspec         admin    false    202            J           1259    16490 
   Field.Line    INDEX     D   CREATE INDEX "Field.Line" ON openspec."Field" USING btree ("Line");
 "   DROP INDEX openspec."Field.Line";
       openspec         admin    false    202            K           1259    16489    Field.Measure    INDEX     J   CREATE INDEX "Field.Measure" ON openspec."Field" USING btree ("Measure");
 %   DROP INDEX openspec."Field.Measure";
       openspec         admin    false    202            L           1259    16488    Field.QtyType    INDEX     J   CREATE INDEX "Field.QtyType" ON openspec."Field" USING btree ("QtyType");
 %   DROP INDEX openspec."Field.QtyType";
       openspec         admin    false    202            M           1259    16487    Field.RW    INDEX     @   CREATE INDEX "Field.RW" ON openspec."Field" USING btree ("RW");
     DROP INDEX openspec."Field.RW";
       openspec         admin    false    202            N           1259    16486 
   Field.Spec    INDEX     D   CREATE INDEX "Field.Spec" ON openspec."Field" USING btree ("Spec");
 "   DROP INDEX openspec."Field.Spec";
       openspec         admin    false    202            O           1259    16485 
   Field.Unit    INDEX     D   CREATE INDEX "Field.Unit" ON openspec."Field" USING btree ("Unit");
 "   DROP INDEX openspec."Field.Unit";
       openspec         admin    false    202            R           1259    16498    History.Spec    INDEX     H   CREATE INDEX "History.Spec" ON openspec."History" USING btree ("Spec");
 $   DROP INDEX openspec."History.Spec";
       openspec         admin    false    204            S           1259    16497    History.UpdateType    INDEX     T   CREATE INDEX "History.UpdateType" ON openspec."History" USING btree ("UpdateType");
 *   DROP INDEX openspec."History.UpdateType";
       openspec         admin    false    204            T           1259    16496    History.UpdateUser    INDEX     T   CREATE INDEX "History.UpdateUser" ON openspec."History" USING btree ("UpdateUser");
 *   DROP INDEX openspec."History.UpdateUser";
       openspec         admin    false    204            W           1259    16501    Ingredient.N    INDEX     H   CREATE INDEX "Ingredient.N" ON openspec."Ingredient" USING btree ("N");
 $   DROP INDEX openspec."Ingredient.N";
       openspec         admin    false    205            X           1259    16500    Ingredient.N-SU    INDEX     N   CREATE INDEX "Ingredient.N-SU" ON openspec."Ingredient" USING btree ("N-SU");
 '   DROP INDEX openspec."Ingredient.N-SU";
       openspec         admin    false    205            Y           1259    16499    Ingredient.N-U    INDEX     L   CREATE INDEX "Ingredient.N-U" ON openspec."Ingredient" USING btree ("N-U");
 &   DROP INDEX openspec."Ingredient.N-U";
       openspec         admin    false    205            \           1259    16508    Line.E    INDEX     <   CREATE INDEX "Line.E" ON openspec."Line" USING btree ("E");
    DROP INDEX openspec."Line.E";
       openspec         admin    false    206            ]           1259    16504    Line.EL    INDEX     >   CREATE INDEX "Line.EL" ON openspec."Line" USING btree ("EL");
    DROP INDEX openspec."Line.EL";
       openspec         admin    false    206            ^           1259    16503    Line.ELf    INDEX     @   CREATE INDEX "Line.ELf" ON openspec."Line" USING btree ("ELf");
     DROP INDEX openspec."Line.ELf";
       openspec         admin    false    206            _           1259    16507    Line.EdL    INDEX     @   CREATE INDEX "Line.EdL" ON openspec."Line" USING btree ("EdL");
     DROP INDEX openspec."Line.EdL";
       openspec         admin    false    206            `           1259    16506 	   Line.EdLf    INDEX     B   CREATE INDEX "Line.EdLf" ON openspec."Line" USING btree ("EdLf");
 !   DROP INDEX openspec."Line.EdLf";
       openspec         admin    false    206            a           1259    16505    Line.Ef    INDEX     >   CREATE INDEX "Line.Ef" ON openspec."Line" USING btree ("Ef");
    DROP INDEX openspec."Line.Ef";
       openspec         admin    false    206            b           1259    16502 	   Line.Spec    INDEX     B   CREATE INDEX "Line.Spec" ON openspec."Line" USING btree ("Spec");
 !   DROP INDEX openspec."Line.Spec";
       openspec         admin    false    206            e           1259    16510    Math.MathName    INDEX     J   CREATE INDEX "Math.MathName" ON openspec."Math" USING btree ("MathName");
 %   DROP INDEX openspec."Math.MathName";
       openspec         admin    false    207            f           1259    16509    Math.MathUnit    INDEX     J   CREATE INDEX "Math.MathUnit" ON openspec."Math" USING btree ("MathUnit");
 %   DROP INDEX openspec."Math.MathUnit";
       openspec         admin    false    207            l           1259    16519    Name_UNIQUE    INDEX     F   CREATE UNIQUE INDEX "Name_UNIQUE" ON openspec."S" USING btree (name);
 #   DROP INDEX openspec."Name_UNIQUE";
       openspec         admin    false    210            i           1259    16511 
   QP.Product    INDEX     K   CREATE INDEX "QP.Product" ON openspec."QueryProd" USING btree ("Product");
 "   DROP INDEX openspec."QP.Product";
       openspec         admin    false    208            m           1259    16518    S,Type    INDEX     :   CREATE INDEX "S,Type" ON openspec."S" USING btree (type);
    DROP INDEX openspec."S,Type";
       openspec         admin    false    210            n           1259    16517    S.CreateUser    INDEX     G   CREATE INDEX "S.CreateUser" ON openspec."S" USING btree (create_user);
 $   DROP INDEX openspec."S.CreateUser";
       openspec         admin    false    210            o           1259    16516    S.LastUpdateUser    INDEX     P   CREATE INDEX "S.LastUpdateUser" ON openspec."S" USING btree (last_update_user);
 (   DROP INDEX openspec."S.LastUpdateUser";
       openspec         admin    false    210            p           1259    16515    S.Owner    INDEX     >   CREATE INDEX "S.Owner" ON openspec."S" USING btree ("Owner");
    DROP INDEX openspec."S.Owner";
       openspec         admin    false    210            q           1259    16514    S.Share    INDEX     <   CREATE INDEX "S.Share" ON openspec."S" USING btree (share);
    DROP INDEX openspec."S.Share";
       openspec         admin    false    210            r           1259    16513    S.Status    INDEX     >   CREATE INDEX "S.Status" ON openspec."S" USING btree (status);
     DROP INDEX openspec."S.Status";
       openspec         admin    false    210            s           1259    16512 	   S.Version    INDEX     B   CREATE INDEX "S.Version" ON openspec."S" USING btree ("Version");
 !   DROP INDEX openspec."S.Version";
       openspec         admin    false    210            v           1259    16524    SS.CurrentLanguage    INDEX     Y   CREATE INDEX "SS.CurrentLanguage" ON openspec."Session" USING btree ("CurrentLanguage");
 *   DROP INDEX openspec."SS.CurrentLanguage";
       openspec         admin    false    211            w           1259    16523    SS.CurrentMode    INDEX     Q   CREATE INDEX "SS.CurrentMode" ON openspec."Session" USING btree ("CurrentMode");
 &   DROP INDEX openspec."SS.CurrentMode";
       openspec         admin    false    211            x           1259    16522    SS.CurrentSpec    INDEX     Q   CREATE INDEX "SS.CurrentSpec" ON openspec."Session" USING btree ("CurrentSpec");
 &   DROP INDEX openspec."SS.CurrentSpec";
       openspec         admin    false    211            y           1259    16521    SS.CurrentUser    INDEX     Q   CREATE INDEX "SS.CurrentUser" ON openspec."Session" USING btree ("CurrentUser");
 &   DROP INDEX openspec."SS.CurrentUser";
       openspec         admin    false    211            z           1259    16520    SS.CurrentVersion    INDEX     W   CREATE INDEX "SS.CurrentVersion" ON openspec."Session" USING btree ("CurrentVersion");
 )   DROP INDEX openspec."SS.CurrentVersion";
       openspec         admin    false    211            }           1259    16526 
   Tree.Child    INDEX     B   CREATE INDEX "Tree.Child" ON openspec."Tree" USING btree (child);
 "   DROP INDEX openspec."Tree.Child";
       openspec         admin    false    212            ~           1259    16525    Tree.Parent    INDEX     D   CREATE INDEX "Tree.Parent" ON openspec."Tree" USING btree (parent);
 #   DROP INDEX openspec."Tree.Parent";
       openspec         admin    false    212            �           1259    16528    Unit.Measure    INDEX     H   CREATE INDEX "Unit.Measure" ON openspec."Unit" USING btree ("Measure");
 $   DROP INDEX openspec."Unit.Measure";
       openspec         admin    false    213            �           1259    16527    Unit.StdUnit    INDEX     H   CREATE INDEX "Unit.StdUnit" ON openspec."Unit" USING btree ("StdUnit");
 $   DROP INDEX openspec."Unit.StdUnit";
       openspec         admin    false    213            �           1259    16530 
   Yield.Math    INDEX     D   CREATE INDEX "Yield.Math" ON openspec."Yield" USING btree ("Math");
 "   DROP INDEX openspec."Yield.Math";
       openspec         admin    false    214            �           1259    16529 
   Yield.Unit    INDEX     D   CREATE INDEX "Yield.Unit" ON openspec."Yield" USING btree ("Unit");
 "   DROP INDEX openspec."Yield.Unit";
       openspec         admin    false    214            �           2606    16571    Blend Blend.C-SU    FK CONSTRAINT     y   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.C-SU" FOREIGN KEY ("C-SU") REFERENCES openspec."Unit"("ID");
 @   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.C-SU";
       openspec       admin    false    2180    213    201            �           2606    16566    Blend Blend.C-U    FK CONSTRAINT     w   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.C-U" FOREIGN KEY ("C-U") REFERENCES openspec."Unit"("ID");
 ?   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.C-U";
       openspec       admin    false    201    2180    213            �           2606    16561    Blend Blend.I    FK CONSTRAINT     n   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.I" FOREIGN KEY ("I") REFERENCES openspec."S"(id);
 =   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.I";
       openspec       admin    false    201    210    2165            �           2606    16556    Blend Blend.Ln    FK CONSTRAINT     u   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.Ln" FOREIGN KEY ("Ln") REFERENCES openspec."Line"("ID");
 >   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.Ln";
       openspec       admin    false    2148    206    201            �           2606    16551    Blend Blend.Pd    FK CONSTRAINT     p   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.Pd" FOREIGN KEY ("Pd") REFERENCES openspec."S"(id);
 >   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.Pd";
       openspec       admin    false    210    201    2165            �           2606    16546    Blend Blend.Pd-SU    FK CONSTRAINT     {   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.Pd-SU" FOREIGN KEY ("Pd-SU") REFERENCES openspec."Unit"("ID");
 A   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.Pd-SU";
       openspec       admin    false    213    201    2180            �           2606    16541    Blend Blend.Pd-U    FK CONSTRAINT     y   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.Pd-U" FOREIGN KEY ("Pd-U") REFERENCES openspec."Unit"("ID");
 @   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.Pd-U";
       openspec       admin    false    201    213    2180            �           2606    16536    Blend Blend.StdSv    FK CONSTRAINT     v   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.StdSv" FOREIGN KEY ("StdSv") REFERENCES openspec."S"(id);
 A   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.StdSv";
       openspec       admin    false    2165    210    201            �           2606    16531    Blend Blend.Sv    FK CONSTRAINT     p   ALTER TABLE ONLY openspec."Blend"
    ADD CONSTRAINT "Blend.Sv" FOREIGN KEY ("Sv") REFERENCES openspec."S"(id);
 >   ALTER TABLE ONLY openspec."Blend" DROP CONSTRAINT "Blend.Sv";
       openspec       admin    false    210    2165    201            �           2606    16631    Field Field.AmountType    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.AmountType" FOREIGN KEY ("AmountType") REFERENCES openspec."S"(id);
 F   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.AmountType";
       openspec       admin    false    210    2165    202            �           2606    16626    Field Field.Expand    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Expand" FOREIGN KEY ("Expand") REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Expand";
       openspec       admin    false    202    210    2165            �           2606    16621    Field Field.FieldType    FK CONSTRAINT     ~   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.FieldType" FOREIGN KEY ("FieldType") REFERENCES openspec."S"(id);
 E   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.FieldType";
       openspec       admin    false    210    2165    202            �           2606    16616    Field Field.Filter    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Filter" FOREIGN KEY ("Filter") REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Filter";
       openspec       admin    false    2165    210    202            �           2606    16611    Field Field.Format    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Format" FOREIGN KEY ("Format") REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Format";
       openspec       admin    false    210    202    2165            �           2606    16606    Field Field.ID    FK CONSTRAINT     p   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.ID" FOREIGN KEY ("ID") REFERENCES openspec."S"(id);
 >   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.ID";
       openspec       admin    false    202    2165    210            �           2606    16601    Field Field.Line    FK CONSTRAINT     y   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Line" FOREIGN KEY ("Line") REFERENCES openspec."Line"("ID");
 @   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Line";
       openspec       admin    false    206    202    2148            �           2606    16596    Field Field.Measure    FK CONSTRAINT     z   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Measure" FOREIGN KEY ("Measure") REFERENCES openspec."S"(id);
 C   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Measure";
       openspec       admin    false    210    202    2165            �           2606    16591    Field Field.QtyType    FK CONSTRAINT     z   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.QtyType" FOREIGN KEY ("QtyType") REFERENCES openspec."S"(id);
 C   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.QtyType";
       openspec       admin    false    210    202    2165            �           2606    16586    Field Field.RW    FK CONSTRAINT     p   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.RW" FOREIGN KEY ("RW") REFERENCES openspec."S"(id);
 >   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.RW";
       openspec       admin    false    210    202    2165            �           2606    16581    Field Field.Spec    FK CONSTRAINT     t   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Spec" FOREIGN KEY ("Spec") REFERENCES openspec."S"(id);
 @   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Spec";
       openspec       admin    false    210    202    2165            �           2606    16576    Field Field.Unit    FK CONSTRAINT     y   ALTER TABLE ONLY openspec."Field"
    ADD CONSTRAINT "Field.Unit" FOREIGN KEY ("Unit") REFERENCES openspec."Unit"("ID");
 @   ALTER TABLE ONLY openspec."Field" DROP CONSTRAINT "Field.Unit";
       openspec       admin    false    2180    202    213            �           2606    16646    History History.Spec    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."History"
    ADD CONSTRAINT "History.Spec" FOREIGN KEY ("Spec") REFERENCES openspec."S"(id);
 D   ALTER TABLE ONLY openspec."History" DROP CONSTRAINT "History.Spec";
       openspec       admin    false    2165    204    210            �           2606    16641    History History.UpdateType    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."History"
    ADD CONSTRAINT "History.UpdateType" FOREIGN KEY ("UpdateType") REFERENCES openspec."S"(id);
 J   ALTER TABLE ONLY openspec."History" DROP CONSTRAINT "History.UpdateType";
       openspec       admin    false    2165    204    210            �           2606    16636    History History.UpdateUser    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."History"
    ADD CONSTRAINT "History.UpdateUser" FOREIGN KEY ("UpdateUser") REFERENCES openspec."S"(id);
 J   ALTER TABLE ONLY openspec."History" DROP CONSTRAINT "History.UpdateUser";
       openspec       admin    false    204    2165    210            �           2606    16666    Ingredient Ingredient.Ln    FK CONSTRAINT        ALTER TABLE ONLY openspec."Ingredient"
    ADD CONSTRAINT "Ingredient.Ln" FOREIGN KEY ("Ln") REFERENCES openspec."Line"("ID");
 H   ALTER TABLE ONLY openspec."Ingredient" DROP CONSTRAINT "Ingredient.Ln";
       openspec       admin    false    205    206    2148            �           2606    16661    Ingredient Ingredient.N    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."Ingredient"
    ADD CONSTRAINT "Ingredient.N" FOREIGN KEY ("N") REFERENCES openspec."S"(id);
 G   ALTER TABLE ONLY openspec."Ingredient" DROP CONSTRAINT "Ingredient.N";
       openspec       admin    false    210    205    2165            �           2606    16656    Ingredient Ingredient.N-SU    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Ingredient"
    ADD CONSTRAINT "Ingredient.N-SU" FOREIGN KEY ("N-SU") REFERENCES openspec."Unit"("ID");
 J   ALTER TABLE ONLY openspec."Ingredient" DROP CONSTRAINT "Ingredient.N-SU";
       openspec       admin    false    213    2180    205            �           2606    16651    Ingredient Ingredient.N-U    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Ingredient"
    ADD CONSTRAINT "Ingredient.N-U" FOREIGN KEY ("N-U") REFERENCES openspec."Unit"("ID");
 I   ALTER TABLE ONLY openspec."Ingredient" DROP CONSTRAINT "Ingredient.N-U";
       openspec       admin    false    2180    213    205            �           2606    16706    Line Line.E    FK CONSTRAINT     l   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.E" FOREIGN KEY ("E") REFERENCES openspec."S"(id);
 ;   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.E";
       openspec       admin    false    206    2165    210            �           2606    16686    Line Line.EL    FK CONSTRAINT     s   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.EL" FOREIGN KEY ("EL") REFERENCES openspec."Line"("ID");
 <   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.EL";
       openspec       admin    false    206    2148    206            �           2606    16681    Line Line.ELf    FK CONSTRAINT     v   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.ELf" FOREIGN KEY ("ELf") REFERENCES openspec."Field"("ID");
 =   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.ELf";
       openspec       admin    false    206    202    2129            �           2606    16701    Line Line.EdL    FK CONSTRAINT     u   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.EdL" FOREIGN KEY ("EdL") REFERENCES openspec."Line"("ID");
 =   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.EdL";
       openspec       admin    false    2148    206    206            �           2606    16696    Line Line.EdLf    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.EdLf" FOREIGN KEY ("EdLf") REFERENCES openspec."Field"("ID");
 >   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.EdLf";
       openspec       admin    false    206    202    2129            �           2606    16691    Line Line.Ef    FK CONSTRAINT     t   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.Ef" FOREIGN KEY ("Ef") REFERENCES openspec."Field"("ID");
 <   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.Ef";
       openspec       admin    false    2129    206    202            �           2606    16676    Line Line.ID    FK CONSTRAINT     n   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.ID" FOREIGN KEY ("ID") REFERENCES openspec."S"(id);
 <   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.ID";
       openspec       admin    false    210    206    2165            �           2606    16671    Line Line.Spec    FK CONSTRAINT     r   ALTER TABLE ONLY openspec."Line"
    ADD CONSTRAINT "Line.Spec" FOREIGN KEY ("Spec") REFERENCES openspec."S"(id);
 >   ALTER TABLE ONLY openspec."Line" DROP CONSTRAINT "Line.Spec";
       openspec       admin    false    206    210    2165            �           2606    16716    Math Math.MathName    FK CONSTRAINT     z   ALTER TABLE ONLY openspec."Math"
    ADD CONSTRAINT "Math.MathName" FOREIGN KEY ("MathName") REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."Math" DROP CONSTRAINT "Math.MathName";
       openspec       admin    false    210    207    2165            �           2606    16711    Math Math.MathUnit    FK CONSTRAINT     z   ALTER TABLE ONLY openspec."Math"
    ADD CONSTRAINT "Math.MathUnit" FOREIGN KEY ("MathUnit") REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."Math" DROP CONSTRAINT "Math.MathUnit";
       openspec       admin    false    207    2165    210            �           2606    16726    QueryProd QP.Product    FK CONSTRAINT     {   ALTER TABLE ONLY openspec."QueryProd"
    ADD CONSTRAINT "QP.Product" FOREIGN KEY ("Product") REFERENCES openspec."S"(id);
 D   ALTER TABLE ONLY openspec."QueryProd" DROP CONSTRAINT "QP.Product";
       openspec       admin    false    2165    208    210            �           2606    16721    QueryProd QP.Query    FK CONSTRAINT     w   ALTER TABLE ONLY openspec."QueryProd"
    ADD CONSTRAINT "QP.Query" FOREIGN KEY ("Query") REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."QueryProd" DROP CONSTRAINT "QP.Query";
       openspec       admin    false    208    2165    210            �           2606    17546    S S,Type    FK CONSTRAINT     j   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S,Type" FOREIGN KEY (type) REFERENCES openspec."S"(id);
 8   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S,Type";
       openspec       admin    false    210    210    2165            �           2606    17541    S S.CreateUser    FK CONSTRAINT     w   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S.CreateUser" FOREIGN KEY (create_user) REFERENCES openspec."S"(id);
 >   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S.CreateUser";
       openspec       admin    false    2165    210    210            �           2606    17536    S S.LastUpdateUser    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S.LastUpdateUser" FOREIGN KEY (last_update_user) REFERENCES openspec."S"(id);
 B   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S.LastUpdateUser";
       openspec       admin    false    210    210    2165            �           2606    17531 	   S S.Owner    FK CONSTRAINT     n   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S.Owner" FOREIGN KEY ("Owner") REFERENCES openspec."S"(id);
 9   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S.Owner";
       openspec       admin    false    2165    210    210            �           2606    17526 	   S S.Share    FK CONSTRAINT     l   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S.Share" FOREIGN KEY (share) REFERENCES openspec."S"(id);
 9   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S.Share";
       openspec       admin    false    210    210    2165            �           2606    17521 
   S S.Status    FK CONSTRAINT     n   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S.Status" FOREIGN KEY (status) REFERENCES openspec."S"(id);
 :   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S.Status";
       openspec       admin    false    210    210    2165            �           2606    16731    S S.Version    FK CONSTRAINT     r   ALTER TABLE ONLY openspec."S"
    ADD CONSTRAINT "S.Version" FOREIGN KEY ("Version") REFERENCES openspec."S"(id);
 ;   ALTER TABLE ONLY openspec."S" DROP CONSTRAINT "S.Version";
       openspec       admin    false    2165    210    210            �           2606    16786    Session SS.CurrentLanguage    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Session"
    ADD CONSTRAINT "SS.CurrentLanguage" FOREIGN KEY ("CurrentLanguage") REFERENCES openspec."S"(id);
 J   ALTER TABLE ONLY openspec."Session" DROP CONSTRAINT "SS.CurrentLanguage";
       openspec       admin    false    2165    210    211            �           2606    16781    Session SS.CurrentMode    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Session"
    ADD CONSTRAINT "SS.CurrentMode" FOREIGN KEY ("CurrentMode") REFERENCES openspec."S"(id);
 F   ALTER TABLE ONLY openspec."Session" DROP CONSTRAINT "SS.CurrentMode";
       openspec       admin    false    210    2165    211            �           2606    16776    Session SS.CurrentSpec    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Session"
    ADD CONSTRAINT "SS.CurrentSpec" FOREIGN KEY ("CurrentSpec") REFERENCES openspec."S"(id);
 F   ALTER TABLE ONLY openspec."Session" DROP CONSTRAINT "SS.CurrentSpec";
       openspec       admin    false    211    2165    210            �           2606    16771    Session SS.CurrentUser    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Session"
    ADD CONSTRAINT "SS.CurrentUser" FOREIGN KEY ("CurrentUser") REFERENCES openspec."S"(id);
 F   ALTER TABLE ONLY openspec."Session" DROP CONSTRAINT "SS.CurrentUser";
       openspec       admin    false    211    210    2165            �           2606    16766    Session SS.CurrentVersion    FK CONSTRAINT     �   ALTER TABLE ONLY openspec."Session"
    ADD CONSTRAINT "SS.CurrentVersion" FOREIGN KEY ("CurrentVersion") REFERENCES openspec."S"(id);
 I   ALTER TABLE ONLY openspec."Session" DROP CONSTRAINT "SS.CurrentVersion";
       openspec       admin    false    210    2165    211            �           2606    16796    Tree Tree.Child    FK CONSTRAINT     r   ALTER TABLE ONLY openspec."Tree"
    ADD CONSTRAINT "Tree.Child" FOREIGN KEY (child) REFERENCES openspec."S"(id);
 ?   ALTER TABLE ONLY openspec."Tree" DROP CONSTRAINT "Tree.Child";
       openspec       admin    false    212    210    2165            �           2606    16791    Tree Tree.Parent    FK CONSTRAINT     t   ALTER TABLE ONLY openspec."Tree"
    ADD CONSTRAINT "Tree.Parent" FOREIGN KEY (parent) REFERENCES openspec."S"(id);
 @   ALTER TABLE ONLY openspec."Tree" DROP CONSTRAINT "Tree.Parent";
       openspec       admin    false    210    212    2165            �           2606    16811    Unit Unit.ID    FK CONSTRAINT     n   ALTER TABLE ONLY openspec."Unit"
    ADD CONSTRAINT "Unit.ID" FOREIGN KEY ("ID") REFERENCES openspec."S"(id);
 <   ALTER TABLE ONLY openspec."Unit" DROP CONSTRAINT "Unit.ID";
       openspec       admin    false    2165    210    213            �           2606    16806    Unit Unit.Measure    FK CONSTRAINT     x   ALTER TABLE ONLY openspec."Unit"
    ADD CONSTRAINT "Unit.Measure" FOREIGN KEY ("Measure") REFERENCES openspec."S"(id);
 A   ALTER TABLE ONLY openspec."Unit" DROP CONSTRAINT "Unit.Measure";
       openspec       admin    false    213    2165    210            �           2606    16801    Unit Unit.StdUnit    FK CONSTRAINT     }   ALTER TABLE ONLY openspec."Unit"
    ADD CONSTRAINT "Unit.StdUnit" FOREIGN KEY ("StdUnit") REFERENCES openspec."Unit"("ID");
 A   ALTER TABLE ONLY openspec."Unit" DROP CONSTRAINT "Unit.StdUnit";
       openspec       admin    false    213    2180    213            �           2606    16826    Yield Yield.Blend    FK CONSTRAINT     |   ALTER TABLE ONLY openspec."Yield"
    ADD CONSTRAINT "Yield.Blend" FOREIGN KEY ("Blend") REFERENCES openspec."Blend"("ID");
 A   ALTER TABLE ONLY openspec."Yield" DROP CONSTRAINT "Yield.Blend";
       openspec       admin    false    214    201    2116            �           2606    16821    Yield Yield.Math    FK CONSTRAINT     y   ALTER TABLE ONLY openspec."Yield"
    ADD CONSTRAINT "Yield.Math" FOREIGN KEY ("Math") REFERENCES openspec."Math"("ID");
 @   ALTER TABLE ONLY openspec."Yield" DROP CONSTRAINT "Yield.Math";
       openspec       admin    false    214    207    2152            �           2606    16816    Yield Yield.Unit    FK CONSTRAINT     y   ALTER TABLE ONLY openspec."Yield"
    ADD CONSTRAINT "Yield.Unit" FOREIGN KEY ("Unit") REFERENCES openspec."Unit"("ID");
 @   ALTER TABLE ONLY openspec."Yield" DROP CONSTRAINT "Yield.Unit";
       openspec       admin    false    2180    213    214            8	      x������ � �      9	      x������ � �      ;	      x������ � �      <	      x������ � �      =	      x������ � �      >	      x������ � �      ?	      x������ � �      A	   �  x����n�6Ư�Л)IER���[ q�� ������#167���̸X�~�b/�/�O��x�ș���|-*�?��9�������Qus[��8�:=`����Xx�}��!�=6:�����|��e�*8f_D��@p����ş��c?<柳�aE�5�I���͸�x>`�dGk'ix��Cx���c���|�Qx0[�J`|dV��,R����;Ů烰m�M��eh��uw���Q)�����#����0��|0r]]=d:���E���lV5��"�N�&u�X��s�'����� n�w�k��^��-� �X��U�:��x�{��Z��'Z�۪\-F�E�^��8��,=7�b'�����1��ƻ�X@#W��n���&�qYԫ\!�nJ��*K���a,n&�҅B�l0��~F��yU�ȯ�q���֠����������Bɝǝg*WEz/������3�ˢVKUa�AN&���$IT]��@�)F(�U�x�2�b�M�����`E����ha�������hκ������pCC��Y����, ���z8o�(kX�Eܧ^����o3d~�%_/H@8�y���m'�2[),ؙ���`��H����x�6s$®�����UXȂ�G�,���c�H��� 6:��|�)o�d����Ou�I�,�D�8��We�!��z����n�Y������u1�G��+�j\�F��`�{���p�eq��C277�0�n�yP�W>v/��:����3	0��x�#����]�d�c�(��� �{�%�";6rs����125 ��/
�'��<��D'��.�Xv�(y`[�R&O ب�=�� ���xUU�H n;�۶��� 	I�e��� X�e���X�e�=����+U���m���G�������2[� ���'��wԢ� ��v���`�����Y�����������`��������)U�)T;]���ĥU��j���K	B�b�;�.�,�mA!]�q~�K�A6�����EY��@Hg�7e����)�����Qs�AY�ކ餐ٺր��Q��$��P�ߤ�]�޻8~�l6���g��s��ξ���������F�
��_�a~�����k�t��MۦO��Y�;~�Ő�7�»/4 <`$��W���)�Z'�w�G���6RRƠ�Q�4r6PӜ]�b��s��C��y1�tا0�U�]��B���,@-t~qa���󌷪�e�h3�S�����;�f)�Q,ͻ�6����=(J=`$J�� ���6��"��,�_�߁���r�7�N`%���no��`vk���,���d��ԩ\���~l�N*�3�Ÿ̗fo�HX3#,�
�x��1l�V��&�Hи;dٰs�rYi�H���H������ ����׍�%� �C�Jt�2H���Bg�Rι�_���B����])�vϹɏ�_0�?!PbSztt䁚��GK����BV��"�×�$�'F�N=�����!�ʈ
���t>��50!��7���"Q�	S1�>�T�Z'�Ha&�n㔥 "���6�2�����G]���!%l׵Nd�"J�6*�URG�҅�Q�Y�|�Y��1cʵ�Rpc��t� f[``Z"�[d�6�H�꨸�zu�	F����f�F�� h�Tc�q���SSU��#9����6�nc����lj��DM�v�����8)�.C�ض�`��0�Ũ�l�p�N\#J�8����>Q�Ւ�Q�qYA�n�5{r\�9������{s}>���>Rr3@7J�M�y'��)ʶZ�&�@秶�b��'�p���p�a%���2�p�/�G�D�z�#�ц}%��B�I�OWY�e6Y��08�y��Q�Y��P�y����@Uh�C�����#���	{[R��{p���zt��t�5��������_�Gi�����Jy	��E������d���X j�y0��n�DAcu�@�зȗ�?(,�X�U��%�j�P\a�t��I�0m��4��zR�閕z4/	���\Nu��y�-ϮO0�+��|-b+Kj�Db�ջ��B� �x�!"pѦn��[	IT�����$fF��3.�F�^ҡ0y7N*�`��
�)��]&��(u�H���!�2�Ię�&Y��&�uj^�g��k�ː��� d��������<��'�k8�7U����9k��1S��r�B�d��Z}D�6��8��S��4S��3(M�䣇@��^�`�VP�^�ޕ~���G����!"��� ��6M6}�Y�k���<���. �����2Y��3�՞�.�5v�༴���"=MI[�f�E� +� ������c�@�8A����j0媂Ć;��E1Ik�u��(&����S�hL=
:���z#�Rp;�afmJr�	��OM���X�K�)
A��YS)�1�uiݦ֯Q?���Y�)���4�M$&_*����u�]���򺎊��~+?���	 @���G t�G�<�n����6k���Z��+Y�]c�h9�� ��v5�Y#=P}��S5���81H�t�fl/B��®�
ËIq
�~�(g�?a�t�~+D�\P��1�m�����;��,�Bo!���v�j�2����?qC��j΅=���2j��
ʩ]ɺ�i���32�͔Ϣ�=b����v��B��D�n�B�ܝ^i����w�-d�xc���@�$�j޳r��:�7���ȓ�ND��˷A�%�[PA��[�$">5��܅
!%��6(`�y�^�?�&ό�M�<7��I�k�oR�ns�m#=�z��* Љ��������y��1�}����G`��a�T��b��W�����m�~i�X��N�?��_���}>��h0��%      B	      x������ � �      C	   G  x�u�Y�� D�]��@�\bN0�?��3]�pGt�Br[G��Z���ɱS:�*M�(��B��Δ�eLN�u�xԗ���l׊�̔����Z>�)G�HB�A��_ri2�1�H�lM�ӡ}G��d�^���vĲ]u��IX�#zs�@o��{�hr
�]��A��{�&d���p��Yfv��$bq�$�#�V�'��H��t�ǝB��_��f�\<��{��=(�"$Cs�+)ж#�>p]w�K�`���1�'Ԅ$ݪa՞T�H�h#J:M[ɀ;���(��w~P�,d���!�6�cbc������J�O�OV�$����;a=��;\x���Bn+ݡ��-��y/j���^���a/�ȁ����i+a�Q����^�	hخ���
(��"7lF�șE��K�҉�3�5%��dPUB*��	\�|f%N���'Ʃ��3g����Ee����ϥ}�m��g�!���	A��	����R�%�ؓ���/:=됥�y�"�'Yx�<),���H�����t�vBf��8�R���/bL���A�R%̌~lX|
�]�«'(D�<go��pƼ�;��L7���Xp���o�4���D!�G`����<��1��N:��2�#���{���J�|f%���<a�\m0%��i&X�#s�^ư�rd����"�;Ҏ���DV�o�ٵ��ɕ5�����͗��ݨ��Pa�w�U�#�E�C�Y��y��$��3o�R*�OƳ%�Q�\T��>�$6S����TQ,���Y��7��HM�kt$G�m{�=���r�fB��%��#r����4/E#1ɑ�|a/.8
#�B�
^�$eD�]��c�90:h'%�r[t� �tt�a�\sD��<cy-;O9/�m����(�@��;b�d}�G�U�'����1��d�����[�O��>=�l8y��k�C�F��h�?M�=�C����C\�t�猴�?v#؊�Sy{O塚�� �nk�E���MH��X���y�Yh������a]�l2Hp|b�q��/��b5��ؠ�(s݈� #2�FF���F ���}��ֈ����Z�׸��V	P�����k����;/�n[7:�U@A[T�ȹ*����A��&uu�%^�zw4'<-��<��W��"?��O�Mrr^�>m�uU��^��ޜ%5^&�4jpI�d<O��/�#s�%X��m<�F���hH6�|�P9�N���k���P9��q�Q9n3��'���u8���]B�<0J�
w�W��2?At��"U>}j_ӌ��xX^D�v>���|�	L�A	>Qy��Iqd�Д<�G"��R�}��fg���f}֍���Q��i?�7;�*�3�HMc0��D�G�t��	�����#�������E�IC,v�oJ�4!�]-G���6�a[ڑ�*�
U~�JY��'�8�?�:��GJ�dmO�uwfO��D���2ȑy�e�׾�=����s{UR�T	,·VB�s���v��E�H����S�+A���WG
�MA	�Xj��A.t���{�~�~�|�����Q}]<]lf�E��p7��y��ӿ�
���|>��"�      D	      x������ � �      E	      x������ � �     