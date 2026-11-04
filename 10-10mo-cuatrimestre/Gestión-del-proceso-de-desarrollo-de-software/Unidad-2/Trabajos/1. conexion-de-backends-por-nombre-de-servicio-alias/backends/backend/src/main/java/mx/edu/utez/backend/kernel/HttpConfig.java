package mx.edu.utez.backend.kernel;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class HttpConfig {

    @Bean
    public RestClient configureRestClient(){
        return RestClient.builder().build();
    }
}
