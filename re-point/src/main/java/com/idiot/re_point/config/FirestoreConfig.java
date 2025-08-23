package com.idiot.re_point.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FirestoreOptions;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
@ConditionalOnProperty(value = "repoint.firestore.enabled", havingValue = "true", matchIfMissing = false)
public class FirestoreConfig {

    @Value("${repoint.firestore.project-id}")
    private String projectId;

    @Bean
    public Firestore firestore() throws IOException {
        // 환경변수 GOOGLE_APPLICATION_CREDENTIALS 를 읽어서 인증
        return FirestoreOptions.newBuilder()
                .setProjectId(projectId) // ← NPE 방지 핵심
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .build()
                .getService();
    }
}