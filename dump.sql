SET FOREIGN_KEY_CHECKS = 0;


    /*
     * Type: Table
     * Name: Product
     * Primary key: id_product
     * --------------------------------
     */

    DROP TABLE IF EXISTS `product`;
    CREATE TABLE `product` (
        `id_product` INT(11) PRIMARY KEY AUTO_INCREMENT,
        `name` VARCHAR(255),
        `price` DECIMAL(8, 2) DEFAULT 0.00,
        `quantity` INT(6) DEFAULT 0,
        `date_add` DATETIME DEFAULT CURRENT_TIMESTAMP,
        `date_edit` DATETIME ON UPDATE CURRENT_TIMESTAMP DEFAULT NULL
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8;

    INSERT INTO `product` (`name`, `price`, `quantity`) VALUES ('Milk', 1.45, 360);
    INSERT INTO `product` (`name`, `price`, `quantity`) VALUES ('Bread', 2.20, 72);
    INSERT INTO `product` (`name`, `price`, `quantity`) VALUES ('Yogurt', 0.99, 152);
    INSERT INTO `product` (`name`, `price`, `quantity`) VALUES ('Fruit', 2.99, 274);
    INSERT INTO `product` (`name`, `price`, `quantity`) VALUES ('Biscuits', 1.49, 95);


    /*
     * Type: Table
     * Name: Sale
     * Primary key: id_sale
     * Foreign key: id_product
     * --------------------------------
     */

    DROP TABLE IF EXISTS `sale`;
    CREATE TABLE `sale` (
        `id_sale` INT(11) PRIMARY KEY AUTO_INCREMENT,
        `id_product` INT(11) NOT NULL,
        `quantity` INT(6),
        `date_add` DATETIME DEFAULT CURRENT_TIMESTAMP,
        `date_edit` DATETIME ON UPDATE CURRENT_TIMESTAMP DEFAULT NULL,
        FOREIGN KEY (`id_product`) REFERENCES `product`(`id_product`)
            ON DELETE CASCADE
            ON UPDATE CASCADE
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8;


    /*
     * Type: Function
     * Name: total
     * Purpose: calculate the total considering the quantity discount
     * Params:
     *      price
     *      quantity
     * --------------------------------
     */

    DROP FUNCTION IF EXISTS `total`;
    DELIMITER $$
    CREATE FUNCTION `total`(`price` DECIMAL(8, 2), `quantity` INT(6))
        RETURNS DECIMAL(8, 2) DETERMINISTIC
        BEGIN
            DECLARE `calc` DECIMAL(8, 2);
            SET `calc` = `price` * `quantity`;

            -- apply 10% discount if the purchased quantity is between 10 and 49 units
            IF quantity > 9 AND quantity < 50 THEN
                SET `calc` = `calc` - (`calc` * 10 / 100);
            END IF;

            -- apply 20% discount if the purchased quantity is between 50 and 99 units
            IF quantity >= 50 AND quantity < 100 THEN
                SET `calc` = `calc` - (`calc` * 20 / 100);
            END IF;

            -- apply 25% discount if the purchased quantity is greater than 100 units
            IF quantity >= 100 THEN
                SET `calc` = `calc` - (`calc` * 25 / 100);
            END IF;

            RETURN `calc`;
        END $$
    DELIMITER ;


    /*
     * Type: View
     * Name: amount
     * Purpose: list of products sold and revenue produced
     * --------------------------------
     */

    DROP VIEW IF EXISTS `amount`;
    CREATE VIEW `amount` AS
        SELECT
            `product`.`name`,
            sum(`sale`.`quantity`) as quantity,
            sum(total(`product`.`price`, `sale`.`quantity`)) AS total
        FROM `product`
        JOIN `sale` USING (`id_product`)
        GROUP BY `product`.`id_product`;


    /*
     * Type: Trigger
     * Name: saleNewProduct
     * Purpose: subtract the quantity sold to the product
     * --------------------------------
     */

    DROP TRIGGER IF EXISTS `saleNewProduct`;
    CREATE TRIGGER `saleNewProduct`
    BEFORE INSERT ON `sale`
    FOR EACH ROW
    CALL setProductQuantity(NEW.quantity, NEW.id_product, 'minus');


    /*
     * Type: Trigger
     * Name: deleteSale
     * Purpose: restore quantity to the product
     * --------------------------------
     */

    DROP TRIGGER IF EXISTS `deleteSale`;
    CREATE TRIGGER `deleteSale`
    BEFORE DELETE ON `sale`
    FOR EACH ROW
    CALL setProductQuantity(OLD.quantity, OLD.id_product, 'add');


    /*
     * Type: Trigger
     * Name: editSale
     * Purpose: recalculates the quantity of the product that has been changed in 'sale' table
     * --------------------------------
     */

    DROP TRIGGER IF EXISTS `editSale`;
    DELIMITER $$
    CREATE TRIGGER `editSale`
    BEFORE UPDATE ON `sale`
    FOR EACH ROW
    BEGIN
        DECLARE operator VARCHAR(5);
        DECLARE diff INT;
        SET operator = 'add';
        SET diff     = OLD.quantity - NEW.quantity;
        IF NEW.quantity > OLD.quantity THEN
            SET operator = 'minus';
            SET diff     = NEW.quantity - OLD.quantity;
        END IF;
        CALL setProductQuantity(diff, OLD.id_product, operator);
    END $$
    DELIMITER ;


    /*
     * Type: Procedure
     * Name: setProductQuantity
     * Purpose: set the quantity to the product
     * --------------------------------
     */

    DROP PROCEDURE IF EXISTS `setProductQuantity`;
    DELIMITER $$
    CREATE PROCEDURE `setProductQuantity` (IN `newQuantity` INT, IN `newId` INT, IN `operator` VARCHAR(5))
    BEGIN
        DECLARE `qta` INT(2);
        SET `qta` = (SELECT `quantity` FROM `product` WHERE `product`.`id_product` = `newId`);
        IF `operator` = 'minus' THEN
            IF `qta` - `newQuantity` >= 0 THEN
                UPDATE `product` SET `quantity` = `quantity` - `newQuantity` WHERE `product`.`id_product` = `newId`;
            ELSE
                SIGNAL SQLSTATE '02000' SET MESSAGE_TEXT = 'The product does not have the desired available quantity';
            END IF;
        ELSE
            UPDATE `product` SET `quantity` = `quantity` + `newQuantity` WHERE `product`.`id_product` = `newId`;
        END IF;
    END $$
    DELIMITER ;


SET FOREIGN_KEY_CHECKS = 1;
