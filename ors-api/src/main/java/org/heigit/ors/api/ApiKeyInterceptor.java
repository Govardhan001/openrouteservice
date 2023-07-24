package org.heigit.ors.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;

@Component
public class ApiKeyInterceptor implements HandlerInterceptor {

    @Value("${app.apikey}")
    private String apiKey;

    @Override
    public boolean preHandle(
            HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        var header = request.getHeader("api-key");
        if (apiKey != null && apiKey.length() > 0 && apiKey.equals(header)) {
            return true;
        } else {
            response.setStatus(401);
            response.setContentType("application/json");
            PrintWriter out = response.getWriter();
            out.println("{\"error\": \"unauthorized\"}");
            out.close();
            return false;
        }
    }

    @Override
    public void postHandle(
            HttpServletRequest request, HttpServletResponse response, Object handler,
            ModelAndView modelAndView) throws Exception {
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception exception) throws Exception {
    }
}
