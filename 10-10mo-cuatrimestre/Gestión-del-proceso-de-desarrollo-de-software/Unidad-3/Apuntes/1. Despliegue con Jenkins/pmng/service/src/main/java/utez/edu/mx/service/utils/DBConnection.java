package utez.edu.mx.service.utils;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;

@Configuration
public class DBConnection {
    @Value("${db.host}")
    private String DB_HOST;

    @Value("${db.port}")
    private String DB_PORT;

    @Value("${db.name}")
    private String DB_NAME;

    @Value("${db.user}")
    private String DB_USER;

    @Value("${db.pass}")
    private String DB_PASS;

    @Bean
    public DataSource getConnection() {
        DriverManagerDataSource src = new DriverManagerDataSource();
        src.setUrl(String.format("jdbc:mysql://%s:%s/%s", DB_HOST, DB_PORT, DB_NAME));
        src.setDriverClassName("com.mysql.cj.jdbc.Driver");
        src.setUsername(DB_USER);
        src.setPassword(DB_PASS);

        return src;
    }
}
