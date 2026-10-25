package mx.edu.utez.backend.test;

import mx.edu.utez.backend.kernel.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

@Service
public class TestService {

    @Value("${api.base.url}")
    private String API_BASE_URL; // = "http://localhost:8081";

    private final RestClient restClient;

    public TestService(RestClient restClient){
        this.restClient = restClient;
    }

    public ApiResponse responderLlamada(){
        ApiResponse response = new ApiResponse(
                "Hola desde backend 1",
                null,
                false,
                HttpStatus.OK
        );

        return response;
    }

    public ApiResponse consultarOtroBackend(){
        System.out.println(API_BASE_URL);
        ApiResponse response = restClient.get()
                .uri(API_BASE_URL + "/test/retrieve")
                .retrieve()
                .body(ApiResponse.class);

        return response;
    }
}
